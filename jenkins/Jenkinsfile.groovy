def buildImage(def options, def imageName) {
    sh "docker build ${options} -t ${imageName} ."
}

def tagImage(def source, def target) {
    sh(script: "docker tag ${source} ${target}")
}

def pushImage(def image) {
    sh "docker push ${image}"
}

def untagImage(def imageName) {
    sh "docker image rm ${imageName}"
}

/**
 * Run an action that requires a Docker registry authentication.
 * @param registryCredentialsId the credentials for the registry authentication will be pulled from the Jenkins credentials store using this credentials id.
 * @param action the registry action to run authenticated.
 */
def withDockerRegistry(def registryCredentialsId, Closure action) {
    def dockerCredentials = usernamePassword(credentialsId: registryCredentialsId, passwordVariable: 'DOCKER_REGISTRY_PASSWORD', usernameVariable: 'DOCKER_REGISTRY_USER')
    withCredentials([dockerCredentials]) {
        def registry = env.DOCKER_REGISTRY
        sh 'docker login --username=${DOCKER_REGISTRY_USER} --password=${DOCKER_REGISTRY_PASSWORD} ' + registry
        try {
            action(registry)
        }
        finally {
            sh "docker logout ${registry}"
        }
    }
}

/**
 * This creates a release tag in the git repository and passes the tag into the closure passed as action parameter.
 * @param projectDir
 * @param credentialsId the credentials for the Git reposiutory authentication will be pulled from the Jenkins credentials store using this credentials id.
 * @param action the registry action to run with a release tag.
 */
def withReleaseTag(def projectDir, def credentialsId, Closure action) {
    def credentials = usernamePassword(credentialsId: credentialsId, usernameVariable: 'GRGIT_USER', passwordVariable: 'GRGIT_PASS')
    withCredentials([credentials]) {

        def dockerRunOptions = "--rm -v ${projectDir}:/project -v dot_gradle:/root/.gradle --workdir=/project"
        if (env.GRADLE_OPTS) {
            dockerRunOptions += " -e GRADLE_OPTS=\"${env.GRADLE_OPTS}\""
        }
        def releaseScope = params.releaseScope
        def releaseStage = params.releaseStage

        def releaseParameters = "-Prelease.scope=${releaseScope} -Prelease.stage=${releaseStage}"
        def releaseTag = sh(script: "docker run ${dockerRunOptions} openjdk:8-jdk ./gradlew --no-daemon --quiet ${releaseParameters} dumpVersion", returnStdout: true).trim()
        sh(script: "docker run ${dockerRunOptions} openjdk:8-jdk ./gradlew --no-daemon -Dorg.ajoberstar.grgit.auth.username=${GRGIT_USER} -Dorg.ajoberstar.grgit.auth.password='${GRGIT_PASS}' ${releaseParameters} --stacktrace release")

        action(releaseTag)
    }
}

node('docker') {
    def isRelease = (params.releaseScope) || (params.releaseStage)
    def projectDir = "${env.JENKINS_AGENT_WORKSPACE}/${env.JOB_NAME}"
    def projectName = "${env.JOB_NAME}_${env.BUILD_NUMBER}"
    def projectSettings = ["PROJECT_DIR=/${projectDir}", "COMPOSE_PROJECT_NAME=${projectName}"]
    def name = "atlassian-bitbucket-base"
    def buildTag = env.BUILD_NUMBER
    def buildImageName = "${name}:${buildTag}"

    def cleanup = {
        untagImage buildImageName
    }

    stage('Prepare') {
        checkout scm
    }

    stage('Build') {
        def gitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        def dockerBuildOptions = " --build-arg VCS_REF=${gitHash} --build-arg VCS_URL=${env.GIT_URL} ${env.DOCKER_BUILD_OPTS ?: ''}"
        try {
            buildImage dockerBuildOptions, buildImageName
        }
        catch (Exception e) {
            currentBuild.result = 'FAILURE'
        }
        finally {
            if (!isRelease) {
                cleanup()
            }
        }
    }

    if (isRelease) {
        stage('Deliver') {
            try {
                withEnv(projectSettings) {
                    withDockerRegistry('nexusDeployer') { def registry ->
                        withReleaseTag(projectDir, 'scm') { def releaseTag ->
                            def releaseImageName = "${registry}${name}:${releaseTag}"
                            tagImage buildImageName, releaseImageName
                            pushImage releaseImageName
                        }
                    }
                }
            }
            catch (Exception e) {
                currentBuild.result = 'FAILURE'
            }
            finally {
                cleanup()
            }
        }
    }
}
