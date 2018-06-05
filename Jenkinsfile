#!/bin/env groovy

node('us-east-1 && ubuntu && docker && !gpu') {

    def dockerTag

    stage('Checkout') {
        checkout scm
        dockerTag = "testdocker"
    }

    def baseImageName = "browser-f/android:${dockerTag}"
    
    stage('Build Artifacts') {
        docker.withRegistry('https://141047255820.dkr.ecr.us-east-1.amazonaws.com'){
            docker.image("${baseImageName}").inside {
                sh '''#!/bin/bash -l
                    set -e
                    set -x
                    cp mozconfigs/artifact.mozconfig mozilla-release/mozconfig
                '''
                sh '''#!/bin/bash -l
                    set -x 
                    set -e 
                    cd mozilla-release
                    ./mach build
                '''
            }
        }
    }
}