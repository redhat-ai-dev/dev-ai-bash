#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# however registry.redhat.io/openshift4/ose-tools-rhel8:latest has jq where as don't think the cli image has jq
# assumes env vars here have been exported and accessible

# Retrieve the UID for the notebook SA, and mark the notebook as owned by it for garbage collection purposes
SA_UID=$(oc get sa ${{ values.name }}-dsp-job -o json | jq -r .metadata.uid)
echo "$SA_UID"
cat <<EOF | oc apply -f -
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  annotations:
    notebooks.opendatahub.io/inject-oauth: 'true'
    opendatahub.io/image-display-name: Minimal Python
    opendatahub.io/accelerator-name: ''
    openshift.io/description: ''
    openshift.io/display-name: ${{ values.name }}-notebook
    notebooks.opendatahub.io/last-image-selection: 's2i-minimal-notebook:2024.1'
    notebooks.opendatahub.io/last-size-selection: Small
  name: ${{ values.name }}-notebook
  namespace: ${{ values.namespace }}
  ownerReferences:
    - apiVersion: v1
      kind: ServiceAccount
      name: ${{ values.name }}-dsp-job
      uid: $SA_UID
  labels:
    app: ${{ values.name }}-notebook
    opendatahub.io/dashboard: 'true'
    opendatahub.io/odh-managed: 'true'
spec:
  template:
    spec:
      affinity: {}
      containers:
        - resources:
            limits:
              cpu: '2'
              memory: 8Gi
            requests:
              cpu: '1'
              memory: 8Gi
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /notebook/${{ values.namespace }}/${{ values.name }}-notebook/api
              port: notebook-port
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          name: ${{ values.name }}-notebook
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /notebook/${{ values.namespace }}/${{ values.name }}-notebook/api
              port: notebook-port
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          env:
            {%- if values.includeModelEndpointSecret %}
            - name: MODEL_ENDPOINT_BEARER
              valueFrom:
                secretKeyRef:
                  name: ${{ values.modelEndpointSecretName }}
                  key: ${{ values.modelEndpointSecretKey }}
            {%- endif %}
            - name: NOTEBOOK_ARGS
              value: |-
                --ServerApp.port=8888
                                  --ServerApp.token=''
                                  --ServerApp.password=''
                                  --ServerApp.base_url=/notebook/${{ values.namespace }}/${{ values.name }}-notebook
                                  --ServerApp.quit_button=False
            - name: JUPYTER_IMAGE
              value: 'image-registry.openshift-image-registry.svc:5000/redhat-ods-applications/custom-sqlite3-odh-minimal-notebook-container:v2-2024a-20240523-sqlite3'
          envFrom:
          - configMapRef:
              name: ${{ values.name }}-model-config
          {%- if values.dbRequired %}
          - configMapRef:
              name: ${{ values.name }}-database-config
          {%- endif %}
          ports:
            - containerPort: 8888
              name: notebook-port
              protocol: TCP
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: /opt/app-root/src
              name: ${{ values.name }}-notebook
            - mountPath: /dev/shm
              name: shm
          image: 'image-registry.openshift-image-registry.svc:5000/redhat-ods-applications/custom-sqlite3-odh-minimal-notebook-container:v2-2024a-20240523-sqlite3'
          workingDir: /opt/app-root/src
      enableServiceLinks: false
      serviceAccountName: ${{ values.name }}-notebook
      volumes:
        - name: ${{ values.name }}-notebook
          persistentVolumeClaim:
            claimName: ${{ values.name }}-notebook-rhoai
        - emptyDir:
            medium: Memory
          name: shm
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  annotations:
    openshift.io/display-name: ${{ values.name }}-notebook-rhoai
  name: ${{ values.name }}-notebook-rhoai
  ownerReferences:
    - apiVersion: v1
      kind: ServiceAccount
      name: ${{ values.name }}-dsp-job
      uid: $SA_UID
  labels:
    opendatahub.io/dashboard: 'true'
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  volumeMode: Filesystem
EOF
