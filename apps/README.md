## Application dev container environment
The intent of this document is to provide a description of the application dev container environment.

Intygstjänster is a collection of some 10-12 applications displaying varying degrees of interaction
with each other. Under some circumstances it might be beneficial to run one or a few of these apps
in docker containers during local development. 



```
apps
└── docker-compose
    ├── frontend-apps
    │   └── frontend-apps.yaml
    ├── spring-apps
    │   ├── ...app dirs...
    │   ├── .spring-app-env
    │   └── spring-apps.yaml
    ├── springboot-apps
    │   ├── ...app dirs...
    │   └── springboot-apps.yaml
    ├── .env    
    ├── docker-compose.yaml
    └── startapps
```