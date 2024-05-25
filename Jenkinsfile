pipeline {
    agent any

    stages {   
        stage('Build with maven') {
            steps {
                sh 'cd SampleWebApp && mvn clean install'
            }
        }
        
             stage('Test') {
            steps {
                sh 'cd SampleWebApp && mvn test'
            }
        
            }
        stage('Code Qualty Scan') {

           steps {
                  withSonarQubeEnv('sonar_scanner') {
             sh "mvn -f SampleWebApp/pom.xml sonar:sonar"      
               }
            }
       }
        stage('Quality Gate') {
          steps {
                 waitForQualityGate abortPipeline: true
              }
        }
        stage('push to nexus') {
            steps {
                nexusArtifactUploader nexusArtifactUploader artifacts: [[artifactId: 'SampleWebApp', classifier: '', file: 'SampleWebApp/targets/SampleWebApp.war', type: 'war']], credentialsId: 'SampleWebApp', groupId: 'SampleWebApp', nexusUrl: 'ec2-18-212-251-67.compute-1.amazonaws.com:8081', nexusVersion: 'nexus3', protocol: 'http', repository: 'Maven_Snapshots', version: '1.0'
            }   
            
        }
        
        stage('deploy to tomcat') {
          steps {
             deploy adapters: [tomcat9(credentialsId: 'Tomcat-server', path: '', url: 'http://3.95.239.55:8080')], contextPath: 'webapp', war: '**/*.war'
              
              
          }
            
        }
            
        }
} 
