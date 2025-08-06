
name: Deploy LLM-Chat to Server

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Deploy LLM-Chat via SSH (password-based)
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          password: ${{ secrets.SERVER_PASSWORD }}
          script: |
            cd /var/www/llm-chat/LLM-Chat
            git pull
            source venv/bin/activate
            pip install -r requirements.txt
            sudo systemctl restart llm-chat
            sudo systemctl status llm-chat
            journalctl -u llm-chat -n 20