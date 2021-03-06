# Puppet module coding standards

В статье описаны принципы, которыми должен руководствоваться разработчик Puppet кода в Авито.

Фиксируя опыт, который был получен в Авито при работе с Puppet, они являются продолжением Coding Standards и Best Practices, использующихся в community и не противоречат им:
- [Module fundamentals](https://puppet.com/docs/puppet/latest/modules_fundamentals.html)
- [Beginner's guide to writing modules](https://puppet.com/docs/puppet/latest/bgtm.html)

## 1. Общие принципы
### 1.1 Фокусируйся на решении одной задачи

Модуль — это базовый блок из которого строится инфраструктура. Модуль разворачивает и управляет частью инфраструктуры, построенной на одной технологии. Хороший модуль имеет понятный API, инкапсулируя в себе логику управления инфраструктурой и фокусируется на решении одной задачи. Монолитный модуль сложно отлаживать, тестировать и переиспользовать.

#### 1.1.1 Модуль должен управлять только ресурсами, необходимыми для решения задачи
Нельзя управлять одним ресурсом из разных мест кода — это приводит к конфликту и проблеме компиляции каталога. Если в модуль для постгреса добавить установку общесистемных отладчиков и профилировщиков, то скорее всего его нельзя будет использовать вместе с модулем, который ставит этот инструментарий. А это уменьшает возможность переиспользования модуля.

Если вам нужно настроить конфигурацию для общесистемного компонента — делайте drop-in конфигурации (если компонент поддерживает include конфигурационных файлов) или используйте базовые модули в контрол репе.

Если нужно использовать системные ресурсы (например пользователя) — выносите его имя в API модуля, чтобы он создавался в контрол репе.

### 1.2 Решай задачу в общем виде
Модуль должен решать задачу в общем виде и не должен содержать site-специфичной логики. Это повышает удобство переиспользования модуля.

Хороший способ проверить это — задать вопрос, могу ли я прямо сейчас отдать модуль другой команде без дополнительных комментариев или пояснений.

## 2. Структура кода
### 2.1 Соблюдай структуру кода, принятой в сообществе

- [Module fundamentals](https://puppet.com/docs/puppet/latest/modules_fundamentals.html)
- [Puppet module design](https://github.com/puppetlabs/best-practices/blob/master/puppet-module-design.md)

### 2.2 Публичные и приватные классы

Классы в модулях делятся на публичные — они предназначены для использования внешними пользователями, и приватные.

Приватные классы должны помечаться @api private через Puppet Strings:

```
# @api private
#
# @summary Installs PostgreSQL
#
# <!-- Официальная документация Puppet Strings: https://puppet.com/docs/puppet/6.2/puppet_strings.html#available-strings-tags -->
class postgresql::install {
```

### 2.3 Параметры это публичный API модуля

Параметры публичных классов это API модуля. Если в модуле используются дефайны — тогда API это параметры этих дефайнов. Это основное, с чем имеет дело пользователь вашего модуля. Поэтому:
- они должны быть хорошо задокументированы, с примерами
- следует избегать обратно несовместимых изменений параметров

#### 2.3.1 Своди количество публичных классов/дефайнов к минимально необходимому

Количество публичных классов следует сводить к минимально необходимому значению. Это упрощает работу с модулем и повышает возможность его переиспользования.

#### 2.3.2 Параметры по-умолчанию в приватных классах должны ссылаться на параметры в публичных

Преположим, модуль разбит на несколько классов, каждый из которых решает свою небольшую задачу, принимая на вход какие-то параметры. Основной класс из init.pp является единственным публичным классом, а остальные  классы — приватными.

Публичный класс модуля k8s:
```
# Разворачивает Kubernetes 1.14
#
# @summary разворачивает Kubernetes 1.14
#
# @param cluster_name
#   Имя кластера
#
# @param master_nodes
#   Список fqdn мастеров
#
# @param dns_cluster_ip
#   ClusterIP dns сервиса
#
# @param version
#   Версия компонентов kubernetes
#
# @param pod_ip_pool
#   Подсеть для адресов подов
#
# @param service_cluster_ip_range
#   Подсеть для адресов сервисов
#
# @param haproxy_dnsname
#   DNS имя, которое резолвится в localhost для взаимодействия компонентов кластера с аписервером через haproxy
#
# @example
#   include k8s
#
# @example hiera
#   k8s::cluster_name: 'omega'
#   k8s::master_nodes:
#     - k8s-master.vagrant
#   k8s::dns_service_ip: '10.100.100.100'
#   k8s::service_cluster_ip_range: '10.100.0.0/16'
#   k8s::haproxy_dnsname: k8s-master.vagrant
#   k8s::calico_as_number: 64000
#   k8s::pod_ip_pool: '10.20.0.10/18'
#
# <!-- Reference: https://puppet.com/docs/puppet/5.5/puppet_strings.html#available-strings-tags -->
class k8s(
  String                                   $cluster_name,
  Array[String]                            $master_nodes,
  String                                   $dns_cluster_ip,
  String                                   $version,
  Stdlib::IP::Address::V4::CIDR            $pod_ip_pool,
  String                                   $service_cluster_ip_range,
  String                                   $haproxy_dnsname,
  Optional[Array[String]]                  $cluster_admin_groups,
 
  # kube-apiserver          
  Integer                                  $kube_apiserver_count,
  Integer                                  $kube_apiserver_audit_log_maxsize,
...
```

В приватном классе параметры по-умолчанию ссылаются на параметры из публичного класса.

Приватный класс модуля k8s:

```
# @api private
#
# Разворачивает docker на нодах кластера
#
# @summary разворачивает docker на нодах кластера
#   https://docs.docker.com/v17.03/engine/reference/commandline/dockerd/
#
# <!-- Reference: https://puppet.com/docs/puppet/5.5/puppet_strings.html#available-strings-tags -->
class k8s::docker(
  $package_name       = $k8s::docker_package_name,
  $version            = $k8s::docker_version,
  $storage_driver     = $k8s::docker_storage_driver,
  $additional_options = $k8s::docker_additional_options,
) {
```

### 2.4 Стандартный набор классов

Для многих инфраструктурных компонентов достаточно стандартного набора классов:

- **%MODULE_NAME%** — основной класс, находится в init.pp. Является единственным публичным классом, все параметры передаются в него
- **install** — содержит все ресурсы, которые нужны для установки инфраструктурного компонента
- **configure** — ресурсы, относящиеся к конфигурированию компонента
- **service** — все относящееся компоненту в запущенном состоянии

### 2.5 Указание параметров по-умолчанию
#### 2.5.1 В манифесте класса

В большистве случаев такой вариант является предпочтительным. Он более читаем по сравнению с остальными и только в этом случае дефолтные значения попадут в автогенерированную документацию к классу.

```
class pulp::agent (
  Hash $server = {
    host              => 'forge.msk.avito.ru',
    port              => 443,
    api_prefix        => '/pulp/api',
    verify_ssl        => false,
    ca_path           => '/etc/ssl/pulp/ca.crt',
    upload_chunk_size => 1048576
  },
  Hash $client = {
    role => 'admin'
  },
  Hash $filesystem = {
    extensions_dir     => '/usr/lib/pulp/admin/extensions',
    id_cert_dir        => '~/.pulp',
    id_cert_filename   => 'user-cert.pem',
    upload_working_dir => '~/.pulp/uploads'
  },
  Hash $output = {
    poll_frequency_in_seconds => 1,
    enable_color              => true,
    wrap_to_terminal          => false,
    wrap_width                => 80
  },
) {
```

#### 2.5.2 В hiera-иерархии модуля
Если параметры по-умолчаню меняются в зависимости от версии дистрибутива, имени ДЦ, в котором расположена машина, количества памяти или других Puppet фактов, следует использовать hiera модуля. Она обеспечивает такую гибкость за счёт иерархии, которую можно настраивать.

hiera.yaml:
```
---
version: 5
 
defaults:
  datadir: data
 
hierarchy:
  - name: "Yaml backend"
    data_hash: yaml_data
    paths:
      - "distrib/debian%{lsbmajdistrelease}.yaml"
      - "common.yaml"
```

В data/distrib/debian8.yaml и debian9.yaml будут лежать параметры по-умолчанию, которые должны отличаться в зависимости от дистрибутива.

Иерархию можно менять в зависимости от необходимости, но в ней по понятным причинам не должно быть слоя node.

#### 2.5.3 Наследование от params.pp

Устаревший способ передачи параметров. Использовался до того, как в модулях появилась hiera и решал ту же задачу. Использование такого подхода не рекомендовано.

### 2.6 Валидация входных данных
#### 2.6.1 Валидируй все входные параметры в публичных классах

Валидация параметров должна осуществляться как можно ближе к месту где их передают — а именно в публичных классах

#### 2.6.2 Для валидации используй через Data Types

> Подробнее про валидацию параметров  можно почитать на этих страницах:
> 
> - [Data type syntax](https://puppet.com/docs/puppet/latest/lang_data_type.html)
> - [Core data types](https://puppet.com/docs/puppet/latest/lang_data_type.html#core-data-types)
> - [Abstract data types](https://puppet.com/docs/puppet/latest/lang_data_type.html#abstract-data-types)


Data Types не позволяют скомпилировать каталог, если на вход передана переменная не того типа.

Если на вход принимаются данные сложных типов, и при их описании страдает читаемость — следует использовать [Type aliases](https://puppet.com/docs/puppet/latest/lang_type_aliases.html).

#### 2.6.3 Если не хватает Data Types, валидируй параметры в коде класса

Если валидацией типа не получается закрыть все возможные плохие значения, можно добавить логику валидации прямо в код, в начало класса. Если валидация не пройдена - делать fail() с описанием того, что именно не так в переданных параметрах.

### 2.7 Используй тот тип ресурса, который лучше подходит для решения задачи
#### 2.7.1 Классы

Класс это набор ресурсов. Нельзя применять более одного класса на одной  ноде.

#### 2.7.2 Дефайны

Дефайн это описание кастомного типа ресурсов. Позволяет сгруппировать логику и сформировать для нее свою абстракцию. На ноде может быть несколько разных ресурсов одного и того же типа (при условии, что у них разные названия).

#### 2.7.3 Функции

> Также про ресурсы можно почитать на странице:
> - [Puppet](https://cf.avito.ru/display/BD/Puppet)

Функции позволяют сгруппировать логику обработки каких-либо данных. Функции удобнее тестировать, т.к. это можно делать независимо от остального кода –

Если функция вносит изменения в конфигурацию, то обязательно должна быть обеспечена идемпотентность.

### 2.8 Hiera
#### 2.8.1 Не рекомендуется использовать hiera_lookup

Использование hiera_lookup в коде класса создаёт неявную зависимость в модуле. Это затрудняет его использование и делает его API более запутанным.

В исключительных случаях это допускатеся, при условии, что hiera_lookup идёт в самом начале класса.

## 3. Тестирование кода
### 3.1 Юнит тесты
#### 3.1.1 На каждый класс/дефайн/функцию должен быть как минимум один юнит тест

В идеале, должно быть 100% покрытие инфраструктурного кода тестами. Обычно это не сложно, потому что как правило сложной логики в инфраструктурном коде нет. Юнит тест должен проверять успешную компиляцию каталога.

#### 3.1.2 Используй юнит тесты чтобы зафиксировать контракт

Если в коде есть какой-то ресурс, наличие которого крайне важно – кроме проверки компиляции каталога, можно добавить проверку этого ресурса. Таким образом в тестах будет зафиксированы требования к коду.

```
context 'enforce limits cron' do
  it do
    should contain_file('/usr/local/bin/enforce-lxd-limits.py').with_ensure('present')
    should contain_cron('enforce-lxd-limits')
      .with(
        'ensure' => 'present',
        'hour' => '*',
        'environment' => %r{MAILTO=.+@.+},
      )
      .without(['weekday', 'month', 'monthday'])
      .that_requires('File[/usr/local/bin/enforce-lxd-limits.py]')
  end
end
```

#### 3.1.3 Cоблюдай принятую структуру и нейминг для тестов

На каждую сущность – отдельный файл <NAME>_spec.rb.

Все тесты должны находится в директории spec:
- spec/classes/
- spec/defines
- spec/funtions

### 3.2 Acceptance тесты
#### 3.2.1 Каждый модуль должен содержать как минимум один acceptance тест на публичный класс/дефайн

Сам тест должен проверять основной позитивный сценарий применения кода.

Рекомендуемые тесты:
- сервис запущен, слушает порт и отвечает по нему стандартным образом
- сгенерированный конфиг или конфиги валидны с точки зрения целевого приложения

#### 3.2.2 Cоблюдай принятую структуру и нейминг для тестов

На каждый тест с именем NAME должно быть создано:
- spec/acceptance/<NAME>.pp – манифест, который будет выполнен при запуске сьюта
- spec/acceptance/<NAME>/*_spec.rb – spec-файлы с тестами на InSpec
- spec/data/suites/<NAME>.yaml

### 4. Внешние зависимости
#### 4.1 Внешние зависимости указывай в metadata.json

После перехода всех контрол реп на внутренний forge потребовалось изменить процесс управления зависимостями в модулях. С этого момента Puppetfile в модулях должен содержать указание, использовать данные metadata.json.

Puppetfile:
```
#!/usr/bin/env ruby
#^syntax detection
 
forge "https://forgeapi.puppetlabs.com"
 
# use dependencies defined in metadata.json
metadata
```

Сами же зависимости модуля должны быть указаны в metadata.json в поле **dependencies** таким образом:

metadata.json:
```
{
  "name": "si-base",
  "version": "1.4.0",
  "type": "module",
  "author": "si",
  "summary": "",
  "license": "copyright \"AVITO\"",
  "source": "",
  "dependencies": [
    { "name": "arch/vault", "version_requirement": ">= 2.1.0 < 3.0.0" },
    { "name": "si/users", "version_requirement": ">= 0.4.1 < 1.0.0" },
    { "name": "si/network", "version_requirement": ">= 0.5.0 < 1.0.0" },
...
```
Допускается не использовать version_requirement, если не принципиальна версия зависимого модуля.

#### 4.2 Fixtures и внешние зависимости

Синхронизируй версии внешних зависимостей в .fixtures.yml и в Puppetfile, или мокай их в юнит тестах

## 5. Версионирование
### 5.1 Используй семантическое версионирование

При релизе новой версии используй семантическое версионирование по отношению к тому интерфейсу, который предоставляется пользователю модуля — параметрам в публичным классам модуля. Это поможет владельцам контрол реп избежать проблем с использованием вашего модуля, а именно компиляцей каталога.

Это не снимает проблемы обратно несовместимых изменений с точки зрения управляемой конфигурации («потерянные» сервисы, пакеты, обновление которое ведет к нарушению работы сервиса), но позволяет по крайней мере установить контракт между разработчиком модуля и разработчиком контрол репы.

## 6. Документация
### 6.1 Используй Puppet Strings для документирования классов

> Подробнее про документирование кода можно почитать в следующих статьях:
> - [Documenting modules](https://puppet.com/docs/puppet/latest/modules_documentation.html)
> - [Documenting modules with Puppet Strings](https://puppet.com/docs/puppet/latest/puppet_strings.html)

Для документирования кода мы используем Puppet Strings, которые рендерятся в README.md. Для документирования кода мы следуем best practices, принятом в сообществе.

### 6.2 Все публичные классы должны быть задокументированы

Очень важно написать хорошую документацию для публичных классов, т.к. именно они будут использоваться в control repo.

Пример хорошо задокументированного класса:
```
# <!-- Развернутый ответ на вопрос что делает этот класс -->
# Управляет пользователями на хостах.
# Для всех пользователей запрещает парольную аутентификацию (ставит `*` в поле пароля в `/etc/shadow`).
# Для пользователей, которые описаны на данном хосте, создаёт одноимённую группу, которая становится первичной для данного пользователя. Не изменяет пользователя `root`.
# Отключает аутентификацию по паролю и ssh ключу для пользователей (shell: /usr/sbin/nologin), которые не указаны в параметре (кроме root)
#
# <!-- То же самое, в одну строку. Это будет добавлено в список классов модуля в начале README -->
# @summary управляет пользователями
#
# <!-- Описание параметров. Значения по-умолчанию будут добавлены автоматически (если они указаны в коде манифеста, а не в хиере -->
# @param [Hash] users
#   Хеш с описанием пользователей, которыми необходимо управлять.
#
# @option users [Integer] uid
#   идентификатор пользователя. Желательно задавать, чтобы на всех серверах у одного и того же пользователя был одинаковый uid.
#
# @option users [String] group
#   Первичная группа пользователя.
#
# @option users [String] sshkey
#   указывает, что делать с закрытым SSH-ключом и списком авторизованных ключей пользователя. Может принимать следующие значения:
#     - `ignored`: ничего не делать, оставить как есть.
#     - `managed`: использовать закрытый ключ пользователя, лежащий на хосте по пути `/etc/secrets/sshkeys/<имя пользователя>`; автоматически генерировать список авторизованных ключей (`authorized_keys`) из открытых ключей, лежащих на паппетмастере в директории `/etc/secrets/sshpubkeys` и имеющих названия вида <имя пользователя>_<имя хоста>. Удалить все закрытые ключи, кроме `$sshkeytype`. Используется для системных пользователей типа `sphinx`, `postgres`.
#     - прочие значения: добавить в `authorized_keys` ключ, лежащий по пути `puppet:///modules/<указанное значение>`, удалить все закрытые ключи.
#
<...>
# <!-- Примеры использования классов, в том числе можно приводить примеры параметров в hiera. Рекомендуется приводить столько примеров, сколько нужно для того, чтобы показать различные кейсы использования API класса. -->
# @example
#   include users
#
# @example Hiera: real user
#   users::users:
#     ivpupkin:
#       uid: 6666
#       comment: 'Ivan Pupkin'
#       sshkey: 'pubkeys/ivpupkin.pub' # ssh public key is stored in `puppet:///modules/pubkeys/ivpupkin.pub`
#       nodeaccess: # has full sudo access to host `test`, no access to host `very-important-server` and user access to all other hosts
#         - regexp: '^test$'
#           groups: ['sudo']
#         - regexp: 'very-important-server'
#           ensure: none
#         - regexp: '.*'
#       sudoers: # can run `sudo puppet agent -t` on all servers
#         - command: '/opt/puppetlabs/bin/puppet agent -t'
#
# @example Hiera: system user
#   users::users:
#     postgres:
#       uid: 8100
#       comment: 'PostgreSQL administrator'
#       home: '/var/lib/postgresql'
#       homemode: '0755'
#       sshkey: managed # users's ssh identity will be symlink to /etc/secrets/sshkeys/postgres, which should be managed by vault-sync
#       sshkeytype: ed25519
#       nodeaccess: # has user access to archive01, archive02, db01 and db02
#         - regexp: '^archive0[12]$'
#           groups: []
#         - regexp: '^db0[12]$'
#           groups: []
#       sshaccess: # can ssh from archive* and db* to archive*
#         '^db0[12]$': [ '^archive0[12]$' ]
#         '^archive0[12]$': [ '^archive0[12]$' ]
#
# @example Hiera: dismissed user
#   users::users:
#     johndoe:
#       nodeaccess: # delete dismissed user from all hosts
#         - regexp: '.*'
#           ensure: 'delete'
#
```

### 6.3 Веди Changelog

Значимые изменения в модуле следует указывать в СHANGELOG.md.

Пример:
```
# Changelog
 
# 1.10.2
- добавлен service class для nginx ingress
 
# 1.10.1
- добавил rbac для vault-init
 
# 1.10.0
- calico_pod_ip_pool переменован в pod_ip_pool
- networkdc умеет анонсировать сервисные адреса
 
# 1.9.0
- kube-dns заменен на CoreDNS
- для локального кеширования DNS ответов используется nodelocaldns. Устанавливается даемонсетом на каждую ноду через аддоны
- убрал локальный dnsmasq и dnsmasq-exporter
- k8s_1_14::kubedns_ip переименован в k8s_1_14::dns_cluster_ip
- новый необязательный параметр k8s_1_14::nodelocaldns_ip
- автоматически назначаются леблы на мастер ноды
- добавлен vertical pod autoscaler версии 0.6.3
 
# 1.8.0
- апдейт kube-state-metrics до 1.7.2
- тесты переписаны на beaker (см. ACCEPTANCE.md), добавлен multinode тест
- исправлен адрес, передаваемый в etcd
- версия kubernetes обновлена до 1.14.6
- добавлен навигатор
- множество мелких фиксов
 
# 1.0.3
- убрал lookup из hiera, не работают когда модуль попадает в контрол репу
 
## 1.0.0
- первый релиз, разворачивается без проблем в Vagrant. На реальном железе не тестировался
```
