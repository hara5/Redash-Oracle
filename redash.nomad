job "redash" {
    region = "Almaty"
    datacenters = ["prod-abay", "prod-roza"]
    type = "service"

    update {
        max_parallel = 1
        min_healthy_time = "10s"
        canary = 0
    }
    
    constraint {
        attribute = "${attr.kernel.name}"
        value     = "linux"
    }

    group "redash" {
        count = 1

        restart {
            attempts = 10
            interval = "5m"
            delay = "25s"
            mode = "delay"
        }

        ephemeral_disk {
            size = 300
        }

        task "server" {
            driver = "docker"

            config {
                image = "registry.query.consul:5000/platform/redash:latest"
                command = "server"
                port_map {
                    http = 5000
                }
            }
            env {
                PYTHONUNBUFFERED = 0
                REDASH_LOG_LEVEL = "INFO"
                REDASH_REDIS_URL = "redis://${NOMAD_ADDR_redis_redis}/0"
                REDASH_DATABASE_URL = "YOUR_DB_URI"
                REDASH_COOKIE_SECRET = "YOUR_COOKIE_SECRET"
                REDASH_WEB_WORKERS = 4
                REDASH_MAIL_SERVER = "YOUR_MAIL_SERVER"
                REDASH_MAIL_PORT = 25
                REDASH_MAIL_USE_TLS = true
                REDASH_MAIL_USERNAME = "YOUR_MAIL_USER"
                REDASH_MAIL_PASSWORD = "YOUR_MAIL_PASSWORD"
                REDASH_MAIL_DEFAULT_SENDER = "YOUR_DEFAULT_SENDER"
                // LDAP authorization
                REDASH_LDAP_LOGIN_ENABLED = true
                REDASH_PASSWORD_LOGIN_ENABLED = false
                REDASH_LDAP_URL = "YOUR_LDAP_SERVER"
                REDASH_LDAP_BIND_DN = "YOUR_LDAP_USER"
                REDASH_LDAP_BIND_DN_PASSWORD = "YOUR_LDAP_PASSWORD"
                //REDASH_LDAP_DISPLAY_NAME_KEY = "mailNickname"
                //REDASH_LDAP_EMAIL_KEY = "mailNickname"
                REDASH_LDAP_SEARCH_DN = "YOUR_LDAP_DN"
                REDASH_LDAP_CUSTOM_USERNAME_PROMPT = "Employee Number"
                REDASH_LDAP_SEARCH_TEMPLATE="YOUR_LDAP_FILTER"
            }

            resources {
                memory = 1000
                network {
                    port "http" {}
                }
            }

            service {
                name = "redash"
                port = "http"
                tags = [ "traefik.enable=true" ]
                check {
                    name     = "\"redash\" is up"
                    type     = "tcp"
                    interval = "10s"
                    timeout  = "2s"
                }
            }
        }
        
        task "worker" {
            driver = "docker"
            config {
                image = "registry.query.consul:5000/platform/redash:latest"
                command = "scheduler"
                // port_map {
                //     http = 5000
                // }
            }

            env {
                PYTHONUNBUFFERED = 0
                REDASH_LOG_LEVEL = "INFO"
                REDASH_REDIS_URL = "redis://${NOMAD_ADDR_redis_redis}/0"
                REDASH_DATABASE_URL = "YOUR_DB_URI"
                REDASH_COOKIE_SECRET = "YOUR_COOKIE_SECRET"
                REDASH_WEB_WORKERS = 4
                REDASH_MAIL_SERVER = "YOUR_MAIL_SERVER"
                REDASH_MAIL_PORT = 25
                REDASH_MAIL_USE_TLS = true
                REDASH_MAIL_USERNAME = "YOUR_MAIL_USER"
                REDASH_MAIL_PASSWORD = "YOUR_MAIL_PASSWORD"
                REDASH_MAIL_DEFAULT_SENDER = "YOUR_DEFAULT_SENDER"

            }

            resources {
                memory = 1000
                // cpu = 500
                // network {
                //     port "http" {}
                // }
            }

            // service {
            //     name = "redash-worker"
            //     port = "http"
            //     tags = [ "traefik.enable=true" ]
            //     check {
            //         name     = "\"redash-worker\" is up"
            //         type     = "tcp"
            //         interval = "10s"
            //         timeout  = "2s"
            //     }
            // }
        }

        task "redis" {
            driver = "docker"
            config {
                image = "registry.query.consul:5000/redis:5.0-alpine"
                port_map {
                    redis = 6379
                }
            }

            resources {
                memory = 300
                network {
                    port "redis" {}
                }
            }

            service {
                name = "redash-redis"
                port = "redis"
                tags = [ "traefik.enable=true" ]
                check {
                    name     = "\"redash-redis\" is up"
                    type     = "tcp"
                    interval = "10s"
                    timeout  = "2s"
                }
            }
        }
    }

}