
pipeline {
    agent none

    parameters {
        choice(
                choices: 'dev\nmilestone\nrc\nfinal',
                description: 'Release Stage',
                name: 'releaseStage')
        choice(
                choices: 'patch\nminor\nmajor',
                description: 'Release Scope',
                name: 'releaseScope')
    }

    stages {
        stage('Deliver') {
            agent { label 'docker' }
            steps {
                build (job: 'docker-atlassian-bitbucket-base',  parameters: [string(name: 'releaseStage', value: params.releaseStage), string(name: 'releaseScope', value: params.releaseScope)])
            }
        }
    }
}

