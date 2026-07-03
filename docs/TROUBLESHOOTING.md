# Troubleshooting

## Проверка GitHub

wget -qO- URL

## Проверка FakeIP

nslookup chatgpt.com

Ожидается:

198.18.x.x

## Проверка обычного домена

nslookup vk.com

## Проверка Podkop

uci get podkop.main.user_domains_text

uci get podkop.OpenAI.user_domains_text

## Проверка синхронизации

/root/sync_router_rules.sh
