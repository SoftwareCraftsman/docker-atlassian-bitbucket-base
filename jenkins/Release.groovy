
pipeline {
    agent none

    parameters {
        choice(
                choices: 'final\nrc\nmilestone',
                description: 'Release Stage',
                name: 'releaseStage')
        choice(
                choices: 'major\nminor\npatch',
                description: 'Release Scope',
                name: 'releaseScope')
    }

    stages {
        stage('Release') {
            agent { label 'docker' }
            build (job: 'docker-atlassian-bitbucket-base',  parameters: [string(name: 'releaseStage', value: releaseStage), string(name: 'releaseScope', value: releaseScope)])
        }
    }
}

