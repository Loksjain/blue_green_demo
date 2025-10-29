pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
  }

  parameters {
    string(name: 'REGISTRY', defaultValue: 'your-docker.io/youruser', description: 'Docker registry/repo')
    string(name: 'IMAGE_NAME', defaultValue: 'blue-green-demo', description: 'Image name')
    string(name: 'K8S_NAMESPACE', defaultValue: 'bluegreen-demo', description: 'Kubernetes namespace')
    string(name: 'INGRESS_HOST', defaultValue: 'bluegreen.local', description: 'Host to smoke test (or Service NodePort/LB)')
  }

  environment {
    REGISTRY_CRED = 'REGISTRY_CRED'
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Determine Active/Idle Color') {
      steps {
        sh '''
          set -e
          ACTIVE=$(kubectl -n ${K8S_NAMESPACE} get svc web -o jsonpath='{.spec.selector.version}' 2>/dev/null || true)
          if [ -z "$ACTIVE" ]; then
            ACTIVE=blue
            echo "No Service yet; defaulting ACTIVE=$ACTIVE"
          fi
          if [ "$ACTIVE" = "blue" ]; then IDLE=green; else IDLE=blue; fi
          echo "ACTIVE_COLOR=$ACTIVE" > .color.env
          echo "IDLE_COLOR=$IDLE"   >> .color.env
          cat .color.env
        '''
      }
    }

    stage('Build & Push Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${env.REGISTRY_CRED}", usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            set -e
            source .color.env
            GIT_SHA=$(git rev-parse --short=8 HEAD)
            VERSION=$(date +%Y%m%d-%H%M%S)-$GIT_SHA
            IMAGE="${REGISTRY}/${IMAGE_NAME}:${VERSION}"

            echo "$REG_PASS" | docker login -u "$REG_USER" --password-stdin $(echo ${REGISTRY} | cut -d/ -f1)

            docker build -t "$IMAGE" .
            docker push "$IMAGE"

            echo "VERSION=$VERSION"   > .build.env
            echo "IMAGE=$IMAGE"      >> .build.env
            cat .build.env
          '''
        }
      }
    }

    stage('Deploy to IDLE color') {
      steps {
        sh '''
          set -e
          source .color.env
          source .build.env

          if [ "$IDLE_COLOR" = "blue" ]; then
            TEMPLATE=k8s/deploy-blue.yaml
          else
            TEMPLATE=k8s/deploy-green.yaml
          fi

          sed -e "s|REPLACE_IMAGE|$IMAGE|g" \
              -e "s|REPLACE_VERSION|$VERSION|g" \
              "$TEMPLATE" > .rendered-deploy.yaml

          echo "Applying to $IDLE_COLOR:"
          kubectl -n ${K8S_NAMESPACE} apply -f .rendered-deploy.yaml

          DEPLOY_NAME="web-${IDLE_COLOR}"
          kubectl -n ${K8S_NAMESPACE} rollout status deploy/$DEPLOY_NAME --timeout=120s
        '''
      }
    }

    stage('Smoke Test IDLE color (direct)') {
      steps {
        sh '''
          set -e
          source .color.env

          POD=$(kubectl -n ${K8S_NAMESPACE} get pod -l app=web,version=${IDLE_COLOR} -o jsonpath='{.items[0].metadata.name}')
          echo "Testing pod: $POD"
          kubectl -n ${K8S_NAMESPACE} port-forward "$POD" 18080:8080 >/tmp/pf.log 2>&1 &
          PF_PID=$!
          sleep 2
          curl -sSf http://127.0.0.1:18080/healthz | grep -i ok
          STATUS=$?
          kill $PF_PID || true
          exit $STATUS
        '''
      }
    }

    stage('Switch Traffic to IDLE color') {
      steps {
        sh '''
          set -e
          source .color.env
          echo "Patching Service selector to version=${IDLE_COLOR}"
          kubectl -n ${K8S_NAMESPACE} patch svc web -p "{\"spec\":{\"selector\":{\"app\":\"web\",\"version\":\"${IDLE_COLOR}\"}}}"
          sleep 3
        '''
      }
    }

    stage('Smoke Test via Ingress/Service (post-switch)') {
      steps {
        sh '''
          set -e
          source .color.env
          echo "Hitting http://${INGRESS_HOST}/ ..."
          HTML=$(curl -sSf --max-time 10 http://${INGRESS_HOST}/)
          echo "$HTML" | grep -qi "${IDLE_COLOR^^}"
        '''
      }
    }

  }

  post {
    success {
      sh '''
        source .color.env
        echo "SUCCESS: Now ACTIVE is ${IDLE_COLOR}."
      '''
    }
    failure {
      sh '''
        set -e
        if [ -f .color.env ]; then
          source .color.env
          echo "FAILURE: Attempting to ensure Service points to ${ACTIVE_COLOR}"
          kubectl -n ${K8S_NAMESPACE} patch svc web -p "{\"spec\":{\"selector\":{\"app\":\"web\",\"version\":\"${ACTIVE_COLOR}\"}}}" || true
        fi
      '''
    }
  }
}
