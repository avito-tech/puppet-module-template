# Шаблон Puppet модуля

В этом репозитории находится шаблон модуля, который мы в Авито используем в своей Puppet-инфраструктуре.

Выложен в ознакомительных целях к статье [«Инфраструктура как Код в Авито: уроки, которые мы извлекли»](https://habr.com/ru/company/avito/blog/513008/). Разработка ведётся внутри Авито, этот репозиторий будет поддерживаться по мере возможностей.

## Структура репозитория

```
.
├── CHANGELOG.md
├── data                              # данные для hiera модуля
│   ├── common.yaml
│   └── distrib
├── docs
│   └── avito-coding-standards.md     # Coding-standards для модулей
├── files                             # файлы модуля
├── .fixtures.yml                     # фикстуры для puppet-rspec тестов
├── Gemfile                           # ruby-зависимости для работы с проектом
├── hiera.yaml                        # конфигурация hiera для модуля
├── .kitchen.yml                      # конфигурация test-kitchen
├── lib                               # сюда кладутся фактеры и паппет-функции, написанные на ruby
│   ├── facter
│   └── puppet
|       └──functions
├── manifests                         # директория для манифестов модуля
│   └── init.pp
├── metadata.json                     # файл с метаданными модуля (автор, зависимости, версия и т.п.)
├── .overcommit.yml                   # настройки для overcommit (инструмент для запуска git хуков)
├── Puppetfile                        # здесь описано, что зависимости следует указывать в metadata.json
├── Rakefile
├── README.md
├── .rubocop.yml                      # настройки ruby-линтера
├── spec                              # здесь находятся тесты
│   ├── acceptance
│   ├── classes
│   ├── default_facts.yml
│   ├── facters
│   ├── fixtures
│   ├── functions
│   └── spec_helper.rb
└── templates                         # шаблоны, которые использует этот модуль
```

## Разработка модуля

Перед началом работы нужно установить все зависимости через bundler:

```
bundle install
```

### Валидация кода

Проверка синтаксиса:

```
bundle exec rake validate
```

Запуск Puppet-линтера:

```
bundle exec rake lint
```

Запуск Ruby-линтера:

```
bundle exec rake rubocop
```

Настройки ruby линтера находятся в .rubocop.yml

### Тестирование кода

#### Юнит-тестирование ([rspec-puppet](https://rspec-puppet.com)):

Юнит тесты находятся в директории spec/{classes,defines,functions}. Более подробно про юнит тесты можно прочитать по ссылкам:
- [Unit testing with rspec-puppet — for beginners](https://puppet.com/blog/unit-testing-rspec-puppet-for-beginners/)
- [Rspec-puppet official website](https://rspec-puppet.com/)
- [Rspec-puppet on github](https://github.com/rodjek/rspec-puppet)

Запуск юнит тестов:
```
bundle exec rake spec
```

Удаление фикстур:
```
bundle exec rake spec_clean
```

Подготовка фикстур:
```
bundle exec rake spec_prep
```

#### Acceptance тестирование ([test-kitchen](https://github.com/test-kitchen/test-kitchen))

Acceptance тесты запускаются в Docker, настройки test-kitchen находятся в файле .kitchen.yml. Для запуска тестов потребуется собрать свой Docker образ из Dockerfile.acceptance и добавить его имя в конфигурацию test-kitchen.

Используется [Kitchen Puppet](https://github.com/neillturner/kitchen-puppet).

Запуск acceptance тестов:
```
bundle exec kitchen test -t spec/acceptance
```

Тесты пишутся на [inspec](https://www.inspec.io) и помещаются в spec/acceptance/<suite_name>/*_spec.rb. 
С примером написанных acceptance тестов можно ознакомиться в репозитории [avito-vault](https://github.com/avito-tech/avito-vault).

### Генерация документации

Для документирования кода используется [Puppet Strings](https://puppet.com/docs/puppet/5.5/puppet_strings.html).

Генерация REFERENCE.md из Puppet Strings:
```
bundle exec reake strings:reference
```

### Настройка git-хуков

Для управления git-хуками используется [overcommit](https://github.com/sds/overcommit).
Настройки git-хуков находятся в .overcommit.yml.


## Смотри также

[Puppet module coding standards](docs/avito-coding-standards.md) — стандарты кодирования для модулей в Avito
