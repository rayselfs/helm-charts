{{/*
自維護 Thanos Chart Helper Functions
*/}}

{{- define "thanos.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "thanos.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "thanos.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "thanos.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "thanos.commonLabels" -}}
app.kubernetes.io/name: {{ include "thanos.name" . }}
helm.sh/chart: {{ include "thanos.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{- define "thanos.labels" -}}
{{- $ctx := index . 0 -}}
{{- $component := index . 1 -}}
{{- $labels := dict "app.kubernetes.io/component" $component -}}
{{- $global := merge $labels (include "thanos.commonLabels" $ctx | fromYaml) -}}
{{- if $ctx.Values.commonLabels -}}
{{- $global = merge $global $ctx.Values.commonLabels -}}
{{- end -}}
{{- toYaml $global -}}
{{- end -}}

{{- define "thanos.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ include "thanos.name" . }}
{{- end -}}

{{- define "thanos.namespace" -}}
{{- if .Values.namespaceOverride -}}
{{- .Values.namespaceOverride -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{- define "thanos.componentFullname" -}}
{{- $component := index . 0 -}}
{{- $ctx := index . 1 -}}
{{- printf "%s-%s" (include "thanos.fullname" $ctx) $component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "thanos.serviceAccountName" -}}
{{- $component := index . 0 -}}
{{- $cfg := index . 1 -}}
{{- $ctx := index . 2 -}}
{{- $svcAccount := get $cfg "serviceAccount" -}}
{{- if $svcAccount.create -}}
{{- default (printf "%s-%s" (include "thanos.fullname" $ctx) $component) $svcAccount.name -}}
{{- else -}}
{{- default "default" $svcAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "thanos.objectStoreSecretName" -}}
{{- if .Values.objectStore.secretName -}}
{{- tpl .Values.objectStore.secretName . -}}
{{- else -}}
{{- printf "%s-objstore" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "thanos.image" -}}
{{- $img := .Values.image -}}
{{- $registry := default "" $img.registry -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $img.repository $img.tag -}}
{{- else -}}
{{- printf "%s:%s" $img.repository $img.tag -}}
{{- end -}}
{{- end -}}

{{- define "thanos.pullSecrets" -}}
{{- if .Values.image.pullSecrets }}
imagePullSecrets:
{{- range .Values.image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "thanos.imagePullSecrets" -}}
{{- include "thanos.pullSecrets" . -}}
{{- end -}}

{{- define "thanos.volumePermissions.image" -}}
{{- $img := .Values.volumePermissions.image -}}
{{- $registry := default "" $img.registry -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $img.repository $img.tag -}}
{{- else -}}
{{- printf "%s:%s" $img.repository $img.tag -}}
{{- end -}}
{{- end -}}

{{- define "thanos.queryFrontendConfigMapName" -}}
{{- if .Values.queryFrontend.existingConfigMap -}}
{{- tpl .Values.queryFrontend.existingConfigMap . -}}
{{- else -}}
{{- printf "%s-query-frontend" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "thanos.storegatewayConfigMapName" -}}
{{- if .Values.storegateway.existingConfigMap -}}
{{- tpl .Values.storegateway.existingConfigMap . -}}
{{- else -}}
{{- printf "%s-storegateway" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Common helper functions 替代實現
*/}}

{{- define "common.names.fullname" -}}
{{- include "thanos.fullname" . -}}
{{- end -}}

{{- define "common.names.namespace" -}}
{{- include "thanos.namespace" . -}}
{{- end -}}

{{- define "common.labels.standard" -}}
{{- $customLabels := index . "customLabels" -}}
{{- $ctx := index . "context" -}}
{{- $labels := include "thanos.commonLabels" $ctx | fromYaml -}}
{{- if $customLabels -}}
{{- if kindIs "map" $customLabels -}}
{{- $labels = merge $labels $customLabels -}}
{{- else if kindIs "string" $customLabels -}}
{{- $parsed := $customLabels | fromYaml -}}
{{- if $parsed -}}
{{- $labels = merge $labels $parsed -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- toYaml $labels -}}
{{- end -}}

{{- define "common.labels.matchLabels" -}}
{{- $customLabels := index . "customLabels" -}}
{{- $ctx := index . "context" -}}
{{- $labels := include "thanos.selectorLabels" $ctx | fromYaml -}}
{{- if $customLabels -}}
{{- if kindIs "map" $customLabels -}}
{{- $component := index $customLabels "app.kubernetes.io/component" -}}
{{- if $component -}}
{{- $labels = set $labels "app.kubernetes.io/component" $component -}}
{{- end -}}
{{- else if kindIs "string" $customLabels -}}
{{- $parsed := $customLabels | fromYaml -}}
{{- if $parsed -}}
{{- $component := index $parsed "app.kubernetes.io/component" -}}
{{- if $component -}}
{{- $labels = set $labels "app.kubernetes.io/component" $component -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- toYaml $labels -}}
{{- end -}}

{{- define "common.tplvalues.render" -}}
{{- $value := index . "value" -}}
{{- $ctx := index . "context" -}}
{{- if kindIs "string" $value -}}
{{- tpl $value $ctx -}}
{{- else if kindIs "map" $value -}}
{{- toYaml $value -}}
{{- else if kindIs "slice" $value -}}
{{- toYaml $value -}}
{{- else -}}
{{- $value -}}
{{- end -}}
{{- end -}}

{{- define "common.tplvalues.merge" -}}
{{- $values := index . "values" -}}
{{- $ctx := index . "context" -}}
{{- $result := dict -}}
{{- range $values -}}
{{- if . -}}
{{- if kindIs "map" . -}}
{{- $result = merge $result . -}}
{{- else if kindIs "string" . -}}
{{- $parsed := . | fromYaml -}}
{{- if $parsed -}}
{{- $result = merge $result $parsed -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- toYaml $result -}}
{{- end -}}

{{- define "common.capabilities.statefulset.apiVersion" -}}
apps/v1
{{- end -}}

{{- define "common.capabilities.deployment.apiVersion" -}}
apps/v1
{{- end -}}

{{- define "common.capabilities.networkPolicy.apiVersion" -}}
networking.k8s.io/v1
{{- end -}}

{{- define "common.capabilities.psp.supported" -}}
{{- false -}}
{{- end -}}

{{- define "common.capabilities.policy.apiVersion" -}}
policy/v1beta1
{{- end -}}

{{- define "common.capabilities.podDisruptionBudget.apiVersion" -}}
policy/v1
{{- end -}}

{{- define "common.capabilities.horizontalPodAutoscaler.apiVersion" -}}
autoscaling/v2
{{- end -}}

{{- define "common.secrets.name" -}}
{{- $existingSecret := index . "existingSecret" -}}
{{- $defaultNameSuffix := index . "defaultNameSuffix" -}}
{{- $ctx := index . "context" -}}
{{- if and $existingSecret (kindIs "map" $existingSecret) $existingSecret.name -}}
{{- tpl $existingSecret.name $ctx -}}
{{- else if $defaultNameSuffix -}}
{{- printf "%s-%s" (include "thanos.fullname" $ctx) $defaultNameSuffix -}}
{{- end -}}
{{- end -}}

{{- define "common.secrets.key" -}}
{{- $existingSecret := index . "existingSecret" -}}
{{- $key := index . "key" -}}
{{- $defaultKey := $key -}}
{{- if and $existingSecret (kindIs "map" $existingSecret) $existingSecret.keyMapping -}}
{{- $mapping := $existingSecret.keyMapping -}}
{{- if index $mapping $key -}}
{{- $defaultKey = index $mapping $key -}}
{{- end -}}
{{- end -}}
{{- $defaultKey -}}
{{- end -}}

{{- define "common.secrets.lookup" -}}
{{- $secret := index . "secret" -}}
{{- $key := index . "key" -}}
{{- $defaultValue := index . "defaultValue" -}}
{{- $ctx := index . "context" -}}
{{- default $defaultValue $defaultValue -}}
{{- end -}}

{{- define "common.affinities.pods" -}}
{{- $type := index . "type" -}}
{{- $component := index . "component" -}}
{{- $customLabels := index . "customLabels" -}}
{{- $ctx := index . "context" -}}
{{- if eq $type "soft" -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 1
    podAffinityTerm:
      labelSelector:
        matchLabels:
{{ include "common.labels.matchLabels" (dict "customLabels" $customLabels "context" $ctx) | indent 10 }}
      topologyKey: kubernetes.io/hostname
{{- else if eq $type "hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
{{ include "common.labels.matchLabels" (dict "customLabels" $customLabels "context" $ctx) | indent 8 }}
    topologyKey: kubernetes.io/hostname
{{- end -}}
{{- end -}}

{{- define "common.affinities.nodes" -}}
{{- $type := index . "type" -}}
{{- $key := index . "key" -}}
{{- $values := index . "values" -}}
{{- if and $type $key $values -}}
{{- if eq $type "soft" -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 1
    preference:
      matchExpressions:
        - key: {{ $key }}
          operator: In
          values:
{{ toYaml $values | indent 12 }}
{{- else if eq $type "hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
  - matchExpressions:
      - key: {{ $key }}
        operator: In
        values:
{{ toYaml $values | indent 10 }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "common.compatibility.renderSecurityContext" -}}
{{- $secContext := index . "secContext" -}}
{{- $ctx := index . "context" -}}
{{- if $secContext.enabled -}}
{{- toYaml $secContext -}}
{{- end -}}
{{- end -}}

{{- define "common.resources.preset" -}}
{{- $type := index . "type" -}}
{{- if eq $type "none" -}}
{}
{{- else if eq $type "nano" -}}
requests:
  cpu: 100m
  memory: 128Mi
{{- else if eq $type "micro" -}}
requests:
  cpu: 200m
  memory: 256Mi
{{- else if eq $type "small" -}}
requests:
  cpu: 500m
  memory: 512Mi
{{- else if eq $type "medium" -}}
requests:
  cpu: 1000m
  memory: 1Gi
{{- else if eq $type "large" -}}
requests:
  cpu: 2000m
  memory: 2Gi
{{- else if eq $type "xlarge" -}}
requests:
  cpu: 4000m
  memory: 4Gi
{{- else if eq $type "2xlarge" -}}
requests:
  cpu: 8000m
  memory: 8Gi
{{- else -}}
{}
{{- end -}}
{{- end -}}

{{- define "common.storage.class" -}}
{{- $persistence := index . "persistence" -}}
{{- $global := index . "global" -}}
{{- if $persistence.storageClass -}}
{{- if eq $persistence.storageClass "-" -}}
storageClassName: ""
{{- else -}}
storageClassName: {{ $persistence.storageClass }}
{{- end -}}
{{- else if $global.defaultStorageClass -}}
storageClassName: {{ $global.defaultStorageClass }}
{{- end -}}
{{- end -}}

{{- define "common.warnings.rollingTag" -}}
{{- if . -}}
{{- if not (hasSuffix "-r" .tag) -}}
{{- if not (hasPrefix "sha256:" .tag) -}}
{{- printf "WARNING: Rolling tag detected (%s), please consider using immutable tags" .tag -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "common.warnings.resources" -}}
{{- /* 空實現，不顯示警告 */ -}}
{{- end -}}

{{- define "common.warnings.modifiedImages" -}}
{{- /* 空實現，不顯示警告 */ -}}
{{- end -}}

{{- define "common.errors.insecureImages" -}}
{{- /* 空實現，不顯示錯誤 */ -}}
{{- end -}}

{{/*
Return the proper Thanos bucketweb fullname
*/}}
{{- define "thanos.bucketweb.fullname" -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "bucketweb" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Thanos compactor fullname
*/}}
{{- define "thanos.compactor.fullname" -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "compactor" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Thanos query-frontend fullname
*/}}
{{- define "thanos.query-frontend.fullname" -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "query-frontend" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Thanos query fullname
*/}}
{{- define "thanos.query.fullname" -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "query" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Thanos receive-distributor fullname
*/}}
{{- define "thanos.receive-distributor.fullname" -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "receive-distributor" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Thanos receive fullname
*/}}
{{- define "thanos.receive.fullname" -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "receive" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Thanos compactor fullname
*/}}
{{- define "thanos.ruler.fullname" -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "ruler" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Thanos storegateway fullname
*/}}
{{- define "thanos.storegateway.fullname" -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "storegateway" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the Thanos Objstore configuration secret.
*/}}
{{- define "thanos.objstoreSecretName" -}}
{{- if .Values.existingObjstoreSecret -}}
    {{- printf "%s" (tpl .Values.existingObjstoreSecret $) -}}
{{- else -}}
    {{- printf "%s-objstore-secret" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos Objstore configuration secret key.
*/}}
{{- define "thanos.objstoreSecretKey" -}}
    {{- $defaultKey := "objstore.yml" -}}
    {{- $foundKey := "" -}}
    {{- range .Values.existingObjstoreSecretItems }}
      {{- if and (eq .path $defaultKey) (eq $foundKey "") }}
        {{- $foundKey = .key }}
      {{- end }}
    {{- end }}
    {{- default $defaultKey $foundKey }}
{{- end }}

{{/*
Return true if a secret object should be created
*/}}
{{- define "thanos.createObjstoreSecret" -}}
{{- if and .Values.objstoreConfig (not .Values.existingObjstoreSecret) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the object store config
*/}}
{{- define "thanos.objstoreConfig" -}}
{{- if and .Values.objstoreConfig (not .Values.existingObjstoreSecret) }}
objstore.yml: |-
  {{- include "common.tplvalues.render" (dict "value" .Values.objstoreConfig "context" $) | b64enc | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Return the storegateway config
*/}}
{{- define "thanos.storegatewayConfigMap" -}}
{{- if .Values.storegateway.config }}
config.yml: |-
  {{- include "common.tplvalues.render" (dict "value" .Values.storegateway.config "context" $) | nindent 2 }}
{{- end }}
{{- if .Values.indexCacheConfig }}
index-cache.yml: |-
  {{- include "common.tplvalues.render" (dict "value" .Values.indexCacheConfig "context" $) | nindent 2 }}
{{- end }}
{{- if .Values.bucketCacheConfig }}
bucket-cache.yml: |-
  {{- include "common.tplvalues.render" (dict "value" .Values.bucketCacheConfig "context" $) | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Return the ruler config
*/}}
{{- define "thanos.rulerConfigMap" -}}
{{- if and .Values.ruler.config (not .Values.ruler.existingConfigmap) }}
ruler.yml: |-
  {{- include "common.tplvalues.render" (dict "value" .Values.ruler.config "context" $) | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Return the receive config
*/}}
{{- define "thanos.receiveConfigMap" -}}
hashrings.json: |-
  {{- include "common.tplvalues.render" (dict "value" (include "thanos.receive.config" .) "context" .) | nindent 2 }}
{{- end -}}

{{/*
Return the query config
*/}}
{{- define "thanos.querySDConfigMap" -}}
{{- if and .Values.query.sdConfig (not .Values.query.existingSDConfigmap) }}
servicediscovery.yml: |-
  {{- include "common.tplvalues.render" (dict "value" .Values.query.sdConfig "context" $) | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Return the query frontend config
*/}}
{{- define "thanos.queryFrontendConfigMap" -}}
{{- if and .Values.queryFrontend.config (not .Values.queryFrontend.existingConfigmap) }}
config.yml: |-
  {{- include "common.tplvalues.render" (dict "value" .Values.queryFrontend.config "context" $) | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Return the Thanos HTTPS and basic auth configuration secret.
*/}}
{{- define "thanos.httpConfigEnabled" -}}
{{- if or .Values.existingHttpConfigSecret .Values.https.enabled .Values.auth.basicAuthUsers .Values.httpConfig }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos HTTPS and basic auth configuration secret.
*/}}
{{- define "thanos.httpCertsSecretName" -}}
{{- if .Values.https.existingSecret -}}
    {{- printf "%s" (tpl .Values.https.existingSecret $) -}}
{{- else -}}
    {{- printf "%s-http-certs-secret" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos HTTPS and basic auth configuration secret.
*/}}
{{- define "thanos.httpConfigSecretName" -}}
{{- if .Values.existingHttpConfigSecret -}}
    {{- printf "%s" (tpl .Values.existingHttpConfigSecret $) -}}
{{- else -}}
    {{- printf "%s-http-config-secret" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a secret object should be created
*/}}
{{- define "thanos.createHttpConfigSecret" -}}
{{- if and (not .Values.existingHttpConfigSecret) (or .Values.https.enabled .Values.auth.basicAuthUsers .Values.httpConfig) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos Query Service Discovery configuration configmap.
*/}}
{{- define "thanos.query.SDConfigmapName" -}}
{{- if .Values.query.existingSDConfigmap -}}
    {{- printf "%s" (tpl .Values.query.existingSDConfigmap $) -}}
{{- else -}}
    {{- printf "%s-query-sd" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "thanos.query.createSDConfigmap" -}}
{{- if and .Values.query.sdConfig (not .Values.query.existingSDConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos Ruler configuration configmap.
*/}}
{{- define "thanos.ruler.configmapName" -}}
{{- if .Values.ruler.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.ruler.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-ruler" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the queryURL used by Thanos Ruler.
*/}}
{{- define "thanos.ruler.queryURL" -}}
{{- if and .Values.queryFrontend.enabled .Values.queryFrontend.ingress.enabled .Values.queryFrontend.ingress.hostname .Values.queryFrontend.ingress.overrideAlertQueryURL -}}
    {{- printf "%s://%s" (ternary "https" "http" .Values.queryFrontend.ingress.tls) (tpl .Values.queryFrontend.ingress.hostname .) -}}
{{- else -}}
{{- if .Values.ruler.queryURL -}}
    {{- printf "%s" (tpl .Values.ruler.queryURL $) -}}
{{- else -}}
    {{- printf "http://%s-query.%s.svc.%s:%d" (include "thanos.fullname" . ) .Release.Namespace .Values.clusterDomain (int  .Values.query.service.ports.http) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "thanos.ruler.createConfigmap" -}}
{{- if and .Values.ruler.config (not .Values.ruler.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos storegateway configuration configmap.
*/}}
{{- define "thanos.storegateway.configmapName" -}}
{{- if .Values.storegateway.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.storegateway.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-storegateway" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos Query Frontend configuration configmap.
*/}}
{{- define "thanos.queryFrontend.configmapName" -}}
{{- if .Values.queryFrontend.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.queryFrontend.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-query-frontend" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "thanos.queryFrontend.createConfigmap" -}}
{{- if and .Values.queryFrontend.config (not .Values.queryFrontend.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "thanos.storegateway.createConfigmap" -}}
{{- if and (or .Values.storegateway.config .Values.indexCacheConfig .Values.bucketCacheConfig) (not .Values.storegateway.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (bucketweb)
*/}}
{{- define "thanos.bucketweb.serviceAccountName" -}}
{{- if and (hasKey .Values "bucketweb") .Values.bucketweb.serviceAccount.create -}}
    {{ default (include "thanos.bucketweb.fullname" .) .Values.bucketweb.serviceAccount.name }}
{{- else if hasKey .Values "bucketweb" -}}
    {{ default "default" .Values.bucketweb.serviceAccount.name }}
{{- else -}}
    default
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (compactor)
*/}}
{{- define "thanos.compactor.serviceAccountName" -}}
{{- if .Values.compactor.serviceAccount.create -}}
    {{ default (include "thanos.compactor.fullname" .) .Values.compactor.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.compactor.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (query)
*/}}
{{- define "thanos.query.serviceAccountName" -}}
{{- if .Values.query.serviceAccount.create -}}
    {{ default (include "thanos.query.fullname" .) .Values.query.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.query.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (queryFrontend)
*/}}
{{- define "thanos.query-frontend.serviceAccountName" -}}
{{- if .Values.queryFrontend.serviceAccount.create -}}
    {{ default (include "thanos.query-frontend.fullname" .) .Values.queryFrontend.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.queryFrontend.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (receive)
*/}}
{{- define "thanos.receive.serviceAccountName" -}}
{{- if and (hasKey .Values "receive") .Values.receive.serviceAccount.create -}}
    {{ default (include "thanos.receive.fullname" .) .Values.receive.serviceAccount.name }}
{{- else if hasKey .Values "receive" -}}
    {{ default "default" .Values.receive.serviceAccount.name }}
{{- else -}}
    default
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (receiveDistributor)
*/}}
{{- define "thanos.receive-distributor.serviceAccountName" -}}
{{- if and (hasKey .Values "receiveDistributor") .Values.receiveDistributor.serviceAccount.create -}}
    {{ default (include "thanos.receive-distributor.fullname" .) .Values.receiveDistributor.serviceAccount.name }}
{{- else if hasKey .Values "receiveDistributor" -}}
    {{ default "default" .Values.receiveDistributor.serviceAccount.name }}
{{- else -}}
    default
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (ruler)
*/}}
{{- define "thanos.ruler.serviceAccountName" -}}
{{- if .Values.ruler.serviceAccount.create -}}
    {{ default (include "thanos.ruler.fullname" .) .Values.ruler.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.ruler.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (storegateway)
*/}}
{{- define "thanos.storegateway.serviceAccountName" -}}
{{- if .Values.storegateway.serviceAccount.create -}}
    {{ default (include "thanos.storegateway.fullname" .) .Values.storegateway.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.storegateway.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos Compactor pvc name
*/}}
{{- define "thanos.compactor.pvcName" -}}
{{- if .Values.compactor.persistence.existingClaim -}}
    {{- printf "%s" (tpl .Values.compactor.persistence.existingClaim $) -}}
{{- else -}}
    {{- printf "%s-compactor" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Check if there are rolling tags in the images
*/}}
{{- define "thanos.checkRollingTags" -}}
{{- include "common.warnings.rollingTag" .Values.image -}}
{{- include "common.warnings.rollingTag" .Values.volumePermissions.image -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "thanos.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "thanos.validateValues.objstore" .) -}}
{{- $messages := append $messages (include "thanos.validateValues.ruler.alertmanagers" .) -}}
{{- $messages := append $messages (include "thanos.validateValues.ruler.config" .) -}}
{{- $messages := append $messages (include "thanos.validateValues.sharded.service" .) -}}
{{- $messages := append $messages (include "thanos.validateValues.receive" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Thanos - Objstore configuration */}}
{{- define "thanos.validateValues.objstore" -}}
{{- if and (or (and (hasKey .Values "bucketweb") .Values.bucketweb.enabled) .Values.compactor.enabled .Values.ruler.enabled .Values.storegateway.enabled) (not (include "thanos.createObjstoreSecret" .)) ( not .Values.existingObjstoreSecret) -}}
thanos: objstore configuration
    When enabling Bucket Web, Compactor, Ruler or Store component,
    you must provide a valid objstore configuration.
    There are three alternatives to provide it:
      1) Provide it using the 'objstoreConfig' parameter
      2) Provide it using an existing Secret and using the 'existingObjstoreSecret' parameter
      3) Put your objstore.yml under the 'files/conf/' directory
{{- end -}}

{{- end -}}
{{/* Validate values of Thanos - Objstore configuration */}}
{{- define "thanos.validateValues.receive" -}}
{{- if and (hasKey .Values "receive") .Values.receive.enabled .Values.receive.autoscaling.enabled (eq .Values.receive.mode "standalone") -}}
thanos: receive configuration
    Thanos receive component cannot be enabled with autoscaling and standalone mode at the same time or the receive hashring will not be properly configured.
    To achieve autoscaling,
    1) Set the 'receive.mode' to 'dual-mode' (see ref: https://github.com/thanos-io/thanos/blob/release-0.22/docs/proposals-accepted/202012-receive-split.md)
    2) Set the 'receive.existingConfigMap' the same as here https://github.com/observatorium/thanos-receive-controller/blob/7140e9476289b57b815692c3ec2dfd95b5fb4b6b/examples/manifests/deployment.yaml#L29
    3) Set the 'receive.statefulsetLabels' to:
        controller.receive.thanos.io: thanos-receive-controller
        controller.receive.thanos.io/hashring: default (same as https://github.com/observatorium/thanos-receive-controller/blob/7140e9476289b57b815692c3ec2dfd95b5fb4b6b/examples/manifests/configmap.yaml#L6)
    4) Deploy Thanos Receive Controller as shown here: https://github.com/observatorium/thanos-receive-controller/tree/main/examples/manifests (remember to adjust the namespace according to your environment)
{{- end -}}
{{- end -}}

{{/* Validate values of Thanos - Ruler Alertmanager(s) */}}
{{- define "thanos.validateValues.ruler.alertmanagers" -}}
{{/* Check the emptiness of the values */}}
{{- if and .Values.ruler.enabled ( and (empty .Values.ruler.alertmanagers) (empty .Values.ruler.alertmanagersConfig)) -}}
thanos: ruler alertmanagers
    When enabling Ruler component, you must provide either alermanagers URL(s) or an alertmanagers configuration.
    See https://github.com/thanos-io/thanos/blob/ef94b7e6468d94e2c47943ebf5fc6db24c48d867/docs/components/rule.md#flags and https://github.com/thanos-io/thanos/blob/ef94b7e6468d94e2c47943ebf5fc6db24c48d867/docs/components/rule.md#Configuration for more information.
{{- end -}}
{{/* Check that the values are defined in a mutually exclusive manner */}}
{{- if and .Values.ruler.enabled .Values.ruler.alertmanagers .Values.ruler.alertmanagersConfig -}}
thanos: ruler alertmanagers
    Only one of the following can be used at one time:
        * .Values.ruler.alertmanagers
        * .Values.ruler.alertmanagersConfig
    Otherwise, the configurations will collide and Thanos will error out. Please consolidate your configuration
    into one of the above options.
{{- end -}}
{{- end -}}

{{/* Validate values of Thanos - Ruler configuration */}}
{{- define "thanos.validateValues.ruler.config" -}}
{{- if and .Values.ruler.enabled (not (include "thanos.ruler.createConfigmap" .)) (not .Values.ruler.existingConfigmap) -}}
thanos: ruler configuration
    When enabling Ruler component, you must provide a valid configuration.
    There are three alternatives to provide it:
      1) Provide it using the 'ruler.config' parameter
      2) Provide it using an existing Configmap and using the 'ruler.existingConfigmap' parameter
      3) Put your ruler.yml under the 'files/conf/' directory
{{- end -}}
{{- end -}}

{{/* Validate values of Thanos - number of sharded service properties */}}
{{- define "thanos.validateValues.sharded.service" -}}
{{- if and .Values.storegateway.sharded.enabled (not (empty .Values.storegateway.sharded.service.clusterIPs) ) -}}
{{- if eq "false" (include "thanos.validateValues.storegateway.sharded.length" (dict "property" $.Values.storegateway.sharded.service.clusterIPs "context" $) ) }}
thanos: storegateway.sharded.service.clusterIPs
    The number of shards does not match the number of ClusterIPs $.Values.storegateway.sharded.service.clusterIPs
{{- end -}}
{{- end -}}
{{- if and .Values.storegateway.sharded.enabled (not (empty .Values.storegateway.sharded.service.loadBalancerIPs) ) -}}
{{- if eq "false" (include "thanos.validateValues.storegateway.sharded.length" (dict "property" $.Values.storegateway.sharded.service.loadBalancerIPs "context" $) ) }}
thanos: storegateway.sharded.service.loadBalancerIPs
    The number of shards does not match the number of loadBalancerIPs $.Values.storegateway.sharded.service.loadBalancerIPs
{{- end -}}
{{- end -}}
{{- if and .Values.storegateway.sharded.enabled (not (empty .Values.storegateway.sharded.service.http.nodePorts) ) -}}
{{- if eq "false" (include "thanos.validateValues.storegateway.sharded.length" (dict "property" $.Values.storegateway.sharded.service.http.nodePorts "context" $) ) }}
thanos: storegateway.sharded.service.http.nodePorts
    The number of shards does not match the number of http.nodePorts $.Values.storegateway.sharded.service.http.nodePorts
{{- end -}}
{{- end -}}
{{- if and .Values.storegateway.sharded.enabled (not (empty .Values.storegateway.sharded.service.grpc.nodePorts) ) -}}
{{- if eq "false" (include "thanos.validateValues.storegateway.sharded.length" (dict "property" $.Values.storegateway.sharded.service.grpc.nodePorts "context" $) ) }}
thanos: storegateway.sharded.service.grpc.nodePorts
    The number of shards does not match the number of grpc.nodePorts $.Values.storegateway.sharded.service.grpc.nodePorts
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "thanos.validateValues.storegateway.sharded.length" -}}
{{/* Get number of shards */}}
{{- $shards := int 0 }}
{{- $hashShards := int 1 }}
{{- $timeShards := int 1 }}
{{- if .context.Values.storegateway.sharded.hashPartitioning.shards }}
  {{- $hashShards = int .context.Values.storegateway.sharded.hashPartitioning.shards }}
{{- end }}
{{- if not (empty .context.Values.storegateway.sharded.timePartitioning) }}
  {{- $timeShards = len .context.Values.storegateway.sharded.timePartitioning }}
{{- end }}
{{- $shards = mul $hashShards $timeShards }}
{{- $propertyLength := (len .property) -}}
{{/* Validate property */}}
{{- if ne $shards $propertyLength -}}
false
{{- end }}
{{- end }}

{{/*
Return true if a hashring configmap object should be created
*/}}
{{- define "thanos.receive.createConfigmap" -}}
{{- if and (hasKey .Values "receive") .Values.receive.enabled (not .Values.receive.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos receive hashring configuration configmap.
*/}}
{{- define "thanos.receive.configmapName" -}}
{{- if .Values.receive.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.receive.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-receive" (include "thanos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/* Return the proper pod fqdn of the replica.
Usage:
{{ include "thanos.receive.podFqdn" (dict "root" . "extra" $suffix ) }}
*/}}
{{- define "thanos.receive.podFqdn" -}}
{{- printf "%s-receive-%d.%s-receive-headless.%s.svc.%s" (include "thanos.fullname" .root ) .extra (include "thanos.fullname" .root ) .root.Release.Namespace .root.Values.clusterDomain -}}
{{- end -}}

{{/* Returns a proper configuration when no config is specified
Usage:
{{ include "thanos.receive.config" . }}
*/}}
{{- define "thanos.receive.config" -}}
{{- if not .Values.receive.existingConfigmap }}
{{- if not .Values.receive.config -}}
{{- $endpoints_list := list -}}
{{- $grpc_port := int .Values.receive.containerPorts.grpc -}}
{{- $capnproto_port := int .Values.receive.containerPorts.capnproto -}}
{{- if .Values.receive.service.additionalHeadless -}}
{{- $count := int .Values.receive.replicaCount -}}
{{- $root := . -}}
{{- range $i := until $count -}}
  {{- $podFqdn := (include "thanos.receive.podFqdn" (dict "root" $root "extra" $i)) -}}
  {{- $endpoint := dict "address" (printf "%s:%d" $podFqdn $grpc_port) "capnproto_address" (printf "%s:%d" $podFqdn $capnproto_port) -}}
  {{- $endpoints_list = append $endpoints_list $endpoint -}}
{{- end -}}
{{- else -}}
{{- $endpoint := dict "address" (printf "127.0.0.1:%d" $grpc_port) "capnproto_address" (printf "127.0.0.1:%d" $capnproto_port) -}}
{{- $endpoints_list = append $endpoints_list $endpoint -}}
{{- end -}}
{{- $config := list (dict "endpoints" $endpoints_list) -}}
{{- $config | toPrettyJson -}}
{{- else -}}
{{- if (typeIs "string" .Values.receive.config) }}
{{- .Values.receive.config -}}
{{- else -}}
{{- .Values.receive.config | toPrettyJson -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Labels to use on serviceMonitor.spec.selector and svc.metadata.labels
*/}}
{{- define "thanos.servicemonitor.matchLabels" -}}
{{- if and .Values.metrics.enabled .Values.metrics.serviceMonitor.enabled -}}
prometheus-operator/monitor: 'true'
{{- end }}
{{- end }}

{{/*
Labels to use on serviceMonitor.spec.selector
*/}}
{{- define "thanos.servicemonitor.selector" -}}
{{- include "thanos.servicemonitor.matchLabels" $ }}
{{ if .Values.metrics.serviceMonitor.selector -}}
{{- include "common.tplvalues.render" (dict "value" .Values.metrics.serviceMonitor.selector "context" $)}}
{{- end -}}
{{- end -}}
