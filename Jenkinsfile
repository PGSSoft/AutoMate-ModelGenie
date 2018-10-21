ios.prepareEnv(xcode: "/Applications/Xcode_10.0.app")

ios.runOniOSNode(runBlock: {
  // Unlock Bitbucket Server credentials
  withCredentials([usernamePassword(credentialsId: 'pgs-software-bitbucket-server-danger_user', passwordVariable: 'DANGER_BITBUCKETSERVER_PASSWORD', usernameVariable: 'DANGER_BITBUCKETSERVER_USERNAME')]) {
    // Danger
    stage("Danger") {
      sh '''
        # Danger
        bundle exec danger
      '''
    }
  }  
})
