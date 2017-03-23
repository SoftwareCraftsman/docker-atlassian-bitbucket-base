node('docker') {
    def buildTag = env.BUILD_NUMBER

    def projectDir = "${env.JENKINS_AGENT_WORKSPACE}/${env.JOB_NAME}"
    def projectName = "${env.JOB_NAME}_${env.BUILD_NUMBER}"

    stage('prepare') {
        checkout scm
    }

    def projectSettings = ["PROJECT_DIR=/${projectDir}",
                           "COMPOSE_PROJECT_NAME=${projectName}"]

    def name = "softwarecraftsmen/atlassian-bitbucket-base"

    stage('build') {
        def gitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        sh "docker build --build-arg VCS_REF=${gitHash} -t ${name}:${buildTag} ."
    }

    if ((params.releaseScope) || (params.releaseStage)) {
        def releaseScope = params.releaseScope
        def releaseStage = params.releaseStage

        stage('deliver') {
            withEnv(projectSettings) {
                def scmCredentials = usernamePassword(credentialsId: 'scm', usernameVariable: 'GRGIT_USER', passwordVariable: 'GRGIT_PASS')
                def dockerCredentials = usernamePassword(credentialsId: 'docker-registry', passwordVariable: 'DOCKER_REGISTRY_PASSWORD', usernameVariable: 'DOCKER_REGISTRY_USER')
                withCredentials([dockerCredentials, scmCredentials]) {

                    sh 'docker login --username=${DOCKER_REGISTRY_USER} --password=${DOCKER_REGISTRY_PASSWORD} ${DOCKER_REGISTRY}'
                    releaseTag = sh(script: "docker run --rm -v ${projectDir}:/project -v dot_gradle:/root/.gradle --workdir=/project openjdk:8-jdk ./gradlew --no-daemon --quiet -Prelease.scope=${releaseScope} -Prelease.stage=${releaseStage} dumpVersion", returnStdout: true).trim()
                    sh(script: "docker run --rm -v ${projectDir}:/project -v dot_gradle:/root/.gradle --workdir=/project openjdk:8-jdk ./gradlew --no-daemon -Dorg.ajoberstar.grgit.auth.username=$GRGIT_USER -Dorg.ajoberstar.grgit.auth.password=$GRGIT_PASS -Prelease.scope=${releaseScope} -Prelease.stage=${releaseStage} --info --stacktrace release")

                    sh "docker tag ${name}:${buildTag} ${DOCKER_REGISTRY}${name}:${releaseTag}"
                    sh "docker push ${DOCKER_REGISTRY}${name}:${releaseTag}"
                    sh "docker image rm ${name}:${buildTag}"
                }
            }
        }
    }
}
