library 'infrastructure'

infrastructurePipeline {
    project ='atlassian-bitbucket-base'

    dockerRegistry = [
            credentialsId: 'dockerRegistryDeployer',
            url : "http://${System.getenv().DOCKER_REGISTRY}"
    ]
}
