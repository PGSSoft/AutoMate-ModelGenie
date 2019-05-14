ios.prepareEnv(xcode: "/Applications/Xcode_10.2.app")

// Unlock Bitbucket Server credentials for Danger
def unlockBitbucketDangerCredentials(block) {
  withCredentials([usernamePassword(credentialsId: 'pgs-software-bitbucket-server-danger_user', passwordVariable: 'DANGER_BITBUCKETSERVER_PASSWORD', usernameVariable: 'DANGER_BITBUCKETSERVER_USERNAME')]) {
    block()
  }
}

def unlockGitHubDangerCredentials(block) {
  withCredentials([usernamePassword(credentialsId: 'pgs-github-PGSJenkins-token', passwordVariable: 'DANGER_GITHUB_API_TOKEN', usernameVariable: '')]) {
    block()
  }
}

// Repository detection
def job = env.JOB_NAME.tokenize("/")[-2]
def unlockDangerCredentials = this.&unlockBitbucketDangerCredentials
if (job =~ /.*github.*/) {
  echo "Repo: GitHub"
  unlockDangerCredentials = this.&unlockGitHubDangerCredentials
} else {
  echo "Repo: Bitbucket"
}

// Node
ios.runOniOSNode(runBlock: {
  unlockDangerCredentials() {
    // Danger
    stage("Danger") {
      sh '''
        # Danger
        bundle exec danger
      '''
    }
  }
})
