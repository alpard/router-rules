# Router Rules

## Source of Truth

GitHub является единственным источником пользовательских списков Podkop.

## Правила

Не редактировать user_domains_text вручную.

Все изменения производятся через rules/*.txt.

После изменения:

python3 scripts/build.py

git push

На роутере:

sync_router_rules.sh

## Скрипт

sync_router_rules.sh должен:

- поддерживать пустые категории
- не выполнять restart без изменений
- оставаться обратно совместимым

## Документация

При изменении архитектуры обновляются:

README.md

docs/ARCHITECTURE.md

docs/NEW_ROUTER.md

docs/UPDATE_RULES.md

docs/TROUBLESHOOTING.md

docs/CHANGELOG.md
