ios.prepareEnv(xcode: "/Applications/Xcode_8.3.app")

node("ios") {
  timeout(45) {
    ansiColor('xterm') {

      // Unlock Bitbucket Server credentials
      withCredentials([usernamePassword(credentialsId: 'pgs-software-bitbucket-server-danger_user', passwordVariable: 'DANGER_BITBUCKETSERVER_PASSWORD', usernameVariable: 'DANGER_BITBUCKETSERVER_USERNAME')]) {
        //
        // Stages
        // Prepare node
        // - clean workspace
        // - clone repository
        // - update bundle
        stage("Prepare & clone") {
          deleteDir()
          checkout scm

          sh '''
            # Bundler
            bundle install
          '''
        }

        // Danger
        stage("Danger") {
          sh '''
            # Danger
            bundle exec danger
          '''
        }

        // Clean
        stage("Clean") {
          deleteDir()
        }
      }
    }
  }
}
