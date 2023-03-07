sed -i "s/{IP}/"${ws}"/g" .env.production
npm run build
