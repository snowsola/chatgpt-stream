<template>
  <v-app>
    <v-app-bar
      app
      color="primary"
      dark
    >
      <div class="d-flex align-center">
        <h2>Noland World</h2>
      </div>
      <v-spacer></v-spacer>
      <v-btn @click="refreshPage" icon>
        <v-icon>mdi-refresh</v-icon>
      </v-btn>
    </v-app-bar>

    <v-main>
      <v-container>
        <v-row>
          <v-col class="mb-4">
            <v-list three-line>
              <template v-for="(item, index) in messages">
                <v-subheader
                  v-if="item.header"
                  :key="index"
                  v-text="item.header"
                ></v-subheader>
                <v-divider
                  v-else-if="item.divider"
                  :key="index"
                  :inset="item.inset"
                ></v-divider>
                <v-list-item
                  v-else
                  :key="index"
                >
                  <v-list-item-avatar>
                    <v-img :src="item.avatar"></v-img>
                  </v-list-item-avatar>
                  <v-list-item-content>
                    <v-list-item-title >{{ item.username }}</v-list-item-title>
                    <v-list-item-subtitle>{{ item.createTime }}</v-list-item-subtitle>
                    <v-list-item-subtitle>
                      <Editor
                        mode="viewer"
                        ref="editor"
                        hint="Hint"
                        :outline="false"
                        :render-config="renderConfig"
                        v-model="item.msg"
                        filled
                        :height="item.height"
                        :background-color="item.color"
                        :value="item.msg"
                      ></Editor>
                    </v-list-item-subtitle>
                  </v-list-item-content>
                </v-list-item>
              </template>
            </v-list>
          </v-col>
        </v-row>
        <v-row>
          <v-col class="mb-4">
            <v-textarea
              append-icon="mdi-refresh"
              append-outer-icon="mdi-send"
              v-model="message"
              label="Your question"
              filled
              clearable
              auto-grow
              background-color="yellow lighten-5"
              @click:append="reconnectWs"
              @click:append-outer="sendMessage"
            />
          </v-col>
        </v-row>
      </v-container>
    </v-main>
  </v-app>
</template>

<script>

import { Editor } from "vuetify-markdown-editor";
export default {
  name: 'ChatGPT',

  components: {
    Editor
  },

  data() {
    return {
      message: '',
      ws: null,
      messages: [],
      renderConfig: {
        // Mermaid config
        mermaid: {
          theme: "dark"
        }
      }
    };
  },

  // data: () => ({
  //     message: '',
  //     ws: null,
  //     messages: [],
  //   }),

  created () {
    const vm = this
    vm.wsInit()
  },

  computed: {
  },

  methods: {
    async chat(message) {
      let method = 'POST';

      let baseUrl = "https://proxy.noland.world/?https://chat.noland.world/v1/chat/completions";
      let url = new URL("/", baseUrl);


      let new_request_headers = new Headers();
      new_request_headers.set('Authorization', 'Bearer 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');
      new_request_headers.set('Content-Type', 'application/json');

      let response = await fetch(url.href, {
        method: method,
        headers: new_request_headers,
        mode: 'cors', // no-cors, *cors, same-origin
        cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
        credentials: 'same-origin', // include, *same-origin, omit
        body: JSON.stringify({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "user",
              "content": message
            }
          ]
        })
      })

      let username = ''
      let avatar = ''
      let height = 60
      let color = 'white'
      if (response.status !== 200) {
        username = 'ERROR'
        avatar = require('./assets/error.png')
        height = 60
        color = 'red lighten-5'
      } else {
        username = 'NOLAND WORLD'
        avatar = require('./assets/developer.png')
        height = 360
        color = 'green lighten-5'
      }

      let body = await response.json()
      let msgNew = {
        username: username,
        avatar: avatar,
        color: color,
        msgId: body.id,
        createTime: body.created,
        msg: body.choices[0].message.content,
        height: height,
      }
      const vm = this
      vm.messages.push(msgNew)
      vm.messages.push({ divider: true, inset: true })
    },
		wsInit() {
      // const vm = this
			// vm.ws = new WebSocket(`${vm.BASE_WS}/api/ws/chat`)
			// vm.ws.onmessage = vm.wsOnMessage
			// vm.ws.onopen = vm.wsOnOpen
			// vm.ws.onerror = vm.wsOnError
			// vm.ws.onclose = vm.wsOnClose
		},
		wsOnOpen() {
      const vm = this
      let content = '[CONNECTED]'
      let msg = {
        header: content,
      }
      vm.messages.push(msg)
      console.log(content)
		},
		wsOnError() {
      const vm = this
      let content = '[CONNECT ERROR]'
      let msg = {
        header: content,
      }
      vm.messages.push(msg)
      console.log(content)
		},
		wsOnMessage(e) {
      const vm = this
      let msgRecv = JSON.parse(e.data)
      console.log(e.data)
      let found = false
      vm.messages.forEach((m, i) => {
        if (m.msgId === msgRecv.msgId) {
          found = true
          vm.messages[i].msg = vm.messages[i].msg + msgRecv.msg
        }
      })
      if (!found) {
        let username = ''
        let avatar = ''
        let height = 60
        let color = 'white'
        if ((msgRecv.kind === 'error') || (msgRecv.kind === 'retry')) {
          username = 'ERROR'
          avatar = require('./assets/error.png')
          height = 60
          color = 'red lighten-5'
        } else if (msgRecv.kind === 'receive') {
          username = 'YOU'
          avatar = require('./assets/developer.png')
          height = 60
          color = 'blue lighten-5'
        } else if (msgRecv.kind === 'chat') {
          username = 'NOLAND WORLD'
          avatar = require('./assets/developer.png')
          height = 360
          color = 'green lighten-5'
        }
        let msgNew = {
          username: username,
          avatar: avatar,
          color: color,
          msgId: msgRecv.msgId,
          createTime: msgRecv.createTime,
          msg: msgRecv.msg,
          height: height,
        }
        vm.messages.push(msgNew)
        vm.messages.push({ divider: true, inset: true })

        if (msgRecv.kind === 'retry') {
          vm.reconnectWs()
        }
      }
		},
		wsOnClose() {
      const vm = this
      let content = '[CONNECT CLOSED]'
      let msg = {
        header: content,
      }
      vm.messages.push(msg)
      console.log(content)
		},
    sendMessage () {
      const vm = this
      if (vm.message !== '') {
        //vm.ws.send(vm.message)
        //console.log(vm.message)
        let msgNew = {
          username: 'YOU',
          avatar: require('./assets/developer.png'),
          color: 'blue lighten-5',
          msg: vm.message,
          height: 60,
        }
        vm.messages.push(msgNew)
        vm.messages.push({ divider: true, inset: true })
        vm.chat(vm.message)
      }
    },
    reconnectWs () {
      const vm = this
      vm.ws.close()
      vm.ws = null
      vm.wsInit()
    },
    refreshPage() {
      window.location.reload()
    },
  },
};
</script>
