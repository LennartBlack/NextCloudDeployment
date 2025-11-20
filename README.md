# Nextcloud Kubernetes Cluster - Dokumentation

## Überblick

Diese Dokumentation beschreibt die vollständige Kubernetes-Infrastruktur für ein produktives Nextcloud-Deployment bei EWE NETZ. Das Cluster umfasst eine hochverfügbare Nextcloud-Installation mit integrierten Office-Funktionen, umfassendem Monitoring und automatisiertem Zertifikatsmanagement.

### Cluster-Domain
- **Basis-Domain:** `ewe-netz-backup.de`
- **Nextcloud:** `https://nextcloud.ewe-netz-backup.de`
- **Collabora Office:** `https://collabora.ewe-netz-backup.de`
- **Monitoring-Stack:** `https://prometheus.ewe-netz-backup.de`, `https://grafana.ewe-netz-backup.de`

## Architektur

### Komponenten-Übersicht

Das Cluster besteht aus folgenden Hauptkomponenten:

1. **Nextcloud Application Stack**
   - Nextcloud App (PHP-FPM + Nginx)
   - Collabora Online Office
   - MariaDB Datenbank
   - Redis Cache

2. **Monitoring & Alerting**
   - Prometheus (Metriken-Sammlung)
   - Grafana (Visualisierung)
   - Alertmanager (Benachrichtigungen)
   - Node Exporter, MySQL Exporter, Nextcloud Exporter

3. **Infrastructure Services**
   - NGINX Ingress Controller
   - cert-manager (Let's Encrypt SSL)
   - Sealed Secrets (Secrets Management)

### Namespace-Struktur

```
nextcloud/          # Hauptapplikation und zugehörige Services
monitoring/         # Prometheus-Stack
ingress-nginx/      # Ingress Controller
cert-manager/       # Zertifikatsverwaltung
```

## Detaillierte Komponenten

### 1. Nextcloud Application

#### Deployment-Konfiguration
- **Image:** `nextcloud:29.0.8-fpm`
- **Replicas:** 1
- **Persistent Storage:** 50Gi
- **Resource Requests:** 500m CPU, 512Mi RAM
- **Resource Limits:** 2 CPU, 2Gi RAM

#### Wichtige Konfigurationen

**Trusted Domains:**
```yaml
NEXTCLOUD_TRUSTED_DOMAINS: "nextcloud.ewe-netz-backup.de nextcloud nextcloud.nextcloud.svc.cluster.local"
```

**Redis Integration:**
```yaml
REDIS_HOST: redis
REDIS_HOST_PORT: 6379
REDIS_HOST_PASSWORD: [aus Secret]
```

**Datenbank-Verbindung:**
```yaml
MYSQL_HOST: mariadb
MYSQL_DATABASE: nextcloud
MYSQL_USER: nextcloud
MYSQL_PASSWORD: [aus nextcloud-db-secret]
```

#### Nginx Sidecar
Der Nginx-Sidecar dient als Web-Server für die PHP-FPM-Anwendung:
- **Image:** `nginx:alpine`
- **Port:** 80
- **Konfiguration:** Via ConfigMap mit Nextcloud-optimierten Einstellungen
- **Client Max Body Size:** 10GB für große Datei-Uploads

#### Persistent Volumes
- **nextcloud-data:** 50Gi für Benutzerdaten
- **nextcloud-config:** 1Gi für Konfigurationsdateien

### 2. Collabora Online Office

#### Deployment-Details
- **Image:** `collabora/code:24.04.9.2.1`
- **Replicas:** 1
- **Resource Requests:** 500m CPU, 2Gi RAM
- **Resource Limits:** 2 CPU, 4Gi RAM

#### Konfiguration
```yaml
aliasgroup1: "https://nextcloud.ewe-netz-backup.de"
server_name: "collabora.ewe-netz-backup.de"
extra_params: "--o:ssl.enable=false --o:ssl.termination=true"
DONT_GEN_SSL_CERT: "true"
```

**Wichtig:** SSL-Terminierung erfolgt am Ingress, daher ist SSL in Collabora deaktiviert.

#### Admin-Zugang
- **Username:** admin
- **Password:** Gespeichert in `collabora-secret`

### 3. MariaDB Datenbank

#### StatefulSet-Konfiguration
- **Image:** `mariadb:11.4`
- **Service Name:** mariadb-headless
- **Update Strategy:** RollingUpdate
- **Persistent Storage:** 5Gi

#### Container

**MariaDB Container:**
- **Resource Requests:** 200m CPU, 512Mi RAM
- **Resource Limits:** 1 CPU, 2Gi RAM
- **Port:** 3306

**MySQL Exporter Sidecar:**
- **Image:** `prom/mysqld-exporter:v0.15.1`
- **Port:** 9104 (metrics)
- **Resource Requests:** 50m CPU, 64Mi RAM

#### Datenbank-Initialisierung

Die Datenbank wird beim ersten Start über ein Init-Script konfiguriert:

```sql
-- Exporter-Benutzer für Monitoring
CREATE USER IF NOT EXISTS 'exporter'@'localhost' IDENTIFIED BY [PASSWORD];
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
FLUSH PRIVILEGES;
```

### 4. Redis Cache

#### Deployment-Konfiguration
- **Image:** `redis:7-alpine`
- **Replicas:** 1
- **Resource Requests:** 100m CPU, 128Mi RAM
- **Resource Limits:** 500m CPU, 512Mi RAM

#### Sicherheit
```yaml
args:
  - redis-server
  - --requirepass
  - $(REDIS_PASSWORD)
```

Password wird aus `redis-auth` Secret geladen.

### 5. Monitoring-Stack

#### Prometheus

**Deployment:**
- **Image:** `prom/prometheus:v2.54.1`
- **Port:** 9090
- **Persistent Storage:** 10Gi
- **Scrape Interval:** 15s

**Scrape Targets:**
- Node Exporter (9100)
- MySQL Exporter (9104)
- Nextcloud Exporter (9205)
- cAdvisor (8080)

**Retention:** 15 Tage

#### Alertmanager

**E-Mail-Benachrichtigungen:**
- **SMTP-Server:** smtp.mailbox.org:587
- **Von-Adresse:** lennart.schwartz@mailbox.org
- **An-Adresse:** lennart.schwartz@mailbox.org
- **TLS:** Aktiviert

**Alert-Routing:**
- **Critical Alerts:** Sofortige Benachrichtigung, Wiederholung alle 1h
- **Warning Alerts:** Benachrichtigung nach 30s, Wiederholung alle 4h
- **Security Alerts:** Benachrichtigung nach 10s, Wiederholung alle 2h

**HTML E-Mail-Template:**
Die Alerts werden als formatierte HTML-E-Mails mit Severity-basierter Farbcodierung versendet.

**Inhibit Rules:**
- Critical Alerts unterdrücken Warning/Info Alerts für denselben Alarmtyp

#### Grafana

**Deployment:**
- **Image:** `grafana/grafana:11.2.2`
- **Port:** 3000
- **Persistent Storage:** 1Gi

**Konfiguration:**
- Admin-User und -Password über Secrets
- Prometheus als Datenquelle vorkonfiguriert
- Automatisches Dashboard-Provisioning

**Verfügbare Dashboards:**
1. **Nextcloud Overview:** Allgemeine Nextcloud-Metriken
2. **Nextcloud Performance:** Detaillierte Performance-Kennzahlen
3. **MariaDB Metrics:** Datenbank-Performance und -Status
4. **Redis Metrics:** Cache-Performance

#### Node Exporter

- **DaemonSet:** Läuft auf allen Nodes
- **Image:** `prom/node-exporter:v1.8.2`
- **Port:** 9100
- **Host-Zugriff:** Benötigt für System-Metriken

#### cAdvisor

- **DaemonSet:** Container-Metriken auf allen Nodes
- **Image:** `gcr.io/cadvisor/cadvisor:v0.47.0`
- **Port:** 8080
- **Volumes:** Zugriff auf Docker-Socket und cgroup-Informationen

### 6. Ingress-Konfiguration

#### NGINX Ingress Controller

**Deployment:**
- Konfiguriert über Helm/Manifest
- HTTP/HTTPS Traffic-Routing
- SSL-Terminierung

**Wichtige Einstellungen:**
```yaml
proxy-body-size: "10240m"  # 10GB max. Upload-Größe
ssl-protocols: "TLSv1.2 TLSv1.3"
```

#### Ingress-Ressourcen

**Nextcloud Ingress:**
```yaml
Host: nextcloud.ewe-netz-backup.de
TLS: Managed by cert-manager
Annotations:
  - nginx.ingress.kubernetes.io/proxy-body-size: "10240m"
  - nginx.ingress.kubernetes.io/ssl-redirect: "true"
```

**Collabora Ingress:**
```yaml
Host: collabora.ewe-netz-backup.de
TLS: Managed by cert-manager
Backend: collabora:9980
```

**Monitoring Ingresses:**
- Prometheus: prometheus.ewe-netz-backup.de
- Grafana: grafana.ewe-netz-backup.de
- Alertmanager: alertmanager.ewe-netz-backup.de

### 7. Zertifikatsverwaltung

#### cert-manager

**ClusterIssuer-Konfiguration:**
```yaml
Name: letsencrypt-prod
ACME Server: https://acme-v02.api.letsencrypt.org/directory
Email: lennart.schwartz@ewe-netz.de
Solver: HTTP-01 Challenge via NGINX Ingress
```

**Automatische Zertifikate:**
Alle Ingress-Ressourcen mit entsprechender Annotation erhalten automatisch Let's Encrypt-Zertifikate:

```yaml
cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

**Zertifikats-Renewal:**
- Automatische Erneuerung 30 Tage vor Ablauf
- Validierung via HTTP-01 Challenge

### 8. Secrets Management

#### Sealed Secrets

Alle Secrets werden mit **Sealed Secrets** verschlüsselt gespeichert:

- `sealed-collabora-secret.yaml`
- `sealed-nextcloud-admin-secret.yaml`
- `sealed-nextcloud-db-secret.yaml`
- `sealed-nextcloud-exporter-secret.yaml`
- `sealed-redis-auth.yaml`

**Wichtig:** Die unverschlüsselten Secrets (`secret.yaml`) sind die tatsächlichen Zugangsdaten und müssen bei der Produktivsetzung durch sealed secrets ausgetauscht werden.

#### Secret-Struktur

**nextcloud-admin-secret:**
```yaml
username: admin
password: [verschlüsselt]
```

**nextcloud-db-secret:**
```yaml
password: [verschlüsselt]
```

**redis-auth:**
```yaml
REDIS_PASSWORD: [verschlüsselt]
```

**collabora-secret:**
```yaml
admin-password: [verschlüsselt]
```

**grafana-auth:**
```yaml
admin-password: [verschlüsselt]
admin-user: admin
```

**nextcloud-exporter-secret:**
```yaml
username: [verschlüsselt]
password: [verschlüsselt]
```

## Deployment-Anleitung

### Voraussetzungen

1. **Kubernetes-Cluster:** Version 1.27+
2. **kubectl:** Konfiguriert und auf Cluster zugreifend
3. **Helm:** Version 3+ (für optionale Chart-Installationen)
4. **kubeseal:** Für Sealed Secrets Management

### Installations-Reihenfolge

#### 1. Namespaces erstellen

```bash
kubectl apply -f namespace.yaml
```

#### 2. cert-manager installieren

```bash
kubectl apply -f cert-issuer.yaml
```

#### 3. Sealed Secrets Controller

```bash
# Falls noch nicht installiert
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
```

#### 4. ConfigMaps und Secrets

```bash
# ConfigMaps
kubectl apply -f configmap.yaml
kubectl apply -f nginx-configmap.yaml

# Sealed Secrets (Produktion)
kubectl apply -f sealed-*.yaml

# ODER für Test/Entwicklung
kubectl apply -f secret.yaml
```

#### 5. Datenbank-Stack

```bash
# MariaDB StatefulSet und Service
kubectl apply -f statefulset.yaml
kubectl apply -f mariadb-service.yaml
kubectl apply -f mariadb-backup-cronjob.yaml
```

Warten, bis MariaDB bereit ist:
```bash
kubectl wait --for=condition=ready pod -l app=mariadb -n nextcloud --timeout=300s
```

#### 6. Redis Cache

```bash
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml
```

#### 7. Nextcloud Application

```bash
kubectl apply -f nextcloud-deployment.yaml
kubectl apply -f nextcloud-service.yaml
```

#### 8. Collabora Office

```bash
kubectl apply -f collabora.yaml
```

#### 9. Ingress-Ressourcen

```bash
kubectl apply -f ingress.yaml
```

#### 10. Monitoring-Stack

```bash
# Prometheus
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-service.yaml
kubectl apply -f prometheus-servicemonitor.yaml

# Alertmanager
kubectl apply -f alertmanager-config.yaml
kubectl apply -f alertmanager-deployment.yaml
kubectl apply -f alertmanager-service.yaml

# Grafana
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-service.yaml
kubectl apply -f grafana-dashboards-configmap.yaml

# Exporters
kubectl apply -f node-exporter-daemonset.yaml
kubectl apply -f cadvisor-daemonset.yaml
kubectl apply -f nextcloud-exporter-service.yaml
```

#### 11. Monitoring-Ingresses

```bash
kubectl apply -f monitoring-ingress.yaml
```

### Initiale Nextcloud-Konfiguration

Nach dem ersten Deployment muss Nextcloud initialisiert werden:

```bash
# In Nextcloud-Pod einloggen
kubectl exec -it -n nextcloud deployment/nextcloud -c nextcloud -- bash

# Installation durchführen (automatisch via Environment-Variablen)
# Admin-User wird automatisch aus Secret erstellt
```

### Collabora in Nextcloud einrichten

1. Nextcloud Admin-Interface öffnen: `https://nextcloud.ewe-netz-backup.de`
2. Apps → "Collabora Online" installieren
3. Einstellungen → Collabora Online
4. Server-URL eintragen: `https://collabora.ewe-netz-backup.de`

## Betrieb

### Wichtige kubectl-Befehle

#### Pod-Status überprüfen
```bash
# Nextcloud Namespace
kubectl get pods -n nextcloud

# Monitoring Namespace
kubectl get pods -n monitoring
```

#### Logs anzeigen
```bash
# Nextcloud Logs
kubectl logs -n nextcloud deployment/nextcloud -c nextcloud -f

# MariaDB Logs
kubectl logs -n nextcloud statefulset/mariadb -c mariadb -f

# Prometheus Logs
kubectl logs -n monitoring deployment/prometheus -f
```

#### Service-Status
```bash
# Alle Services
kubectl get svc -A

# Nextcloud Services
kubectl get svc -n nextcloud
```

#### Ingress-Status
```bash
kubectl get ingress -A
```

#### Persistent Volume Claims
```bash
kubectl get pvc -n nextcloud
kubectl get pvc -n monitoring
```

### Skalierung

#### Horizontale Skalierung

**Nextcloud:**
```bash
kubectl scale deployment nextcloud -n nextcloud --replicas=3
```

**Wichtig:** Für Multi-Replica-Setups muss `ReadWriteMany` Storage verwendet werden.

**Collabora:**
```bash
kubectl scale deployment collabora -n nextcloud --replicas=2
```

#### Vertikale Skalierung

Resources in den Deployment-Manifesten anpassen und neu deployen:

```bash
kubectl apply -f nextcloud-deployment.yaml
```

### Updates

#### Nextcloud Update

1. **Backup erstellen**
2. **Image-Version aktualisieren:**
   ```yaml
   image: nextcloud:29.0.9-fpm  # Update notwendig
   ```
3. **Deployment aktualisieren:**
   ```bash
   kubectl apply -f nextcloud-deployment.yaml
   ```
4. **Update-Prozess überwachen:**
   ```bash
   kubectl logs -n nextcloud deployment/nextcloud -c nextcloud -f
   ```

#### Datenbank-Update

MariaDB-Updates sollten schrittweise erfolgen:

1. **Backup erstellen**
2. **Image aktualisieren** (z.B. 11.4 → 11.5)
3. **Rolling Update durchführen:**
   ```bash
   kubectl apply -f statefulset.yaml
   ```

#### Monitoring-Stack Update

```bash
# Prometheus
kubectl set image deployment/prometheus -n monitoring prometheus=prom/prometheus:v2.55.0

# Grafana
kubectl set image deployment/grafana -n monitoring grafana=grafana/grafana:11.3.0
```

### Troubleshooting

#### Nextcloud startet nicht

```bash
# Pod-Events prüfen
kubectl describe pod -n nextcloud -l app=nextcloud

# Logs analysieren
kubectl logs -n nextcloud deployment/nextcloud -c nextcloud --previous

# Häufige Probleme:
# - Datenbank nicht erreichbar → MariaDB-Status prüfen
# - Redis nicht erreichbar → Redis-Status prüfen
# - Permission-Probleme → fsGroup in SecurityContext prüfen
```

#### Datenbank-Verbindungsprobleme

```bash
# MariaDB-Status
kubectl get pods -n nextcloud -l app=mariadb

# In MariaDB einloggen und testen
kubectl exec -it -n nextcloud statefulset/mariadb -c mariadb -- mysql -u root -p

# Verbindung von Nextcloud aus testen
kubectl exec -it -n nextcloud deployment/nextcloud -c nextcloud -- nc -zv mariadb 3306
```

#### SSL-Zertifikat-Probleme

```bash
# Certificate-Status prüfen
kubectl get certificate -A

# Certificate-Details
kubectl describe certificate -n nextcloud nextcloud-tls

# cert-manager Logs
kubectl logs -n cert-manager deployment/cert-manager -f

# Challenge-Status
kubectl get challenges -A
```

#### Performance-Probleme

```bash
# Resource-Nutzung prüfen
kubectl top pods -n nextcloud
kubectl top nodes

# Grafana-Dashboards konsultieren
# https://grafana.ewe-netz-backup.de
```

#### Collabora verbindet nicht mit Nextcloud

1. **Firewall-Regeln prüfen**
2. **Alias-Konfiguration in Collabora verifizieren**
3. **Nextcloud Collabora-App-Einstellungen prüfen**
4. **Logs analysieren:**
   ```bash
   kubectl logs -n nextcloud deployment/collabora -f
   ```

### Monitoring und Alerting

#### Zugriff auf Monitoring-Interfaces

- **Prometheus:** https://prometheus.ewe-netz-backup.de
- **Grafana:** https://grafana.ewe-netz-backup.de
- **Alertmanager:** https://alertmanager.ewe-netz-backup.de

#### Wichtige Metriken

**Nextcloud:**
- Anzahl aktiver Benutzer
- Dateisystem-Nutzung
- PHP-FPM-Pool-Status
- Response Times

**MariaDB:**
- Query-Performance
- Verbindungs-Pool
- Replikations-Lag (falls konfiguriert)
- Buffer-Pool-Nutzung

**Redis:**
- Hit-Rate
- Memory-Nutzung
- Connected Clients
- Eviction-Rate

**System:**
- CPU-Auslastung
- Memory-Nutzung
- Disk I/O
- Network Traffic

#### Alert-Beispiele

Das Cluster ist mit vordefinierten Alerts konfiguriert:

- **HighCPUUsage:** CPU > 80% für 5 Minuten
- **HighMemoryUsage:** Memory > 85% für 5 Minuten
- **DiskSpaceWarning:** Disk > 80% belegt
- **PodCrashLooping:** Pod restart > 5x in 10 Minuten
- **ServiceDown:** Service nicht erreichbar
- **DatabaseConnectionFailed:** DB-Verbindung fehlgeschlagen

## Sicherheit

### Network Policies

Es wird empfohlen, Network Policies zu implementieren.

### Security Context

Alle Pods sollten mit eingeschränkten Privilegien laufen.

### SSL/TLS

- **Alle externen Verbindungen:** Verschlüsselt via Let's Encrypt
- **Interne Verbindungen:** Über Cluster-Netzwerk
- **TLS-Versionen:** TLS 1.2 und 1.3
- **HSTS:** Aktiviert über Ingress-Annotations

## Ressourcen-Übersicht

### CPU-Anforderungen (Gesamt)

| Komponente | Requests | Limits |
|------------|----------|--------|
| Nextcloud | 500m | 2000m |
| Nginx (Sidecar) | 100m | 500m |
| MariaDB | 200m | 1000m |
| MySQL Exporter | 50m | 200m |
| Redis | 100m | 500m |
| Collabora | 500m | 2000m |
| Prometheus | 500m | 2000m |
| Grafana | 100m | 500m |
| Alertmanager | 100m | 500m |
| Node Exporter | 100m | 200m (pro Node) |
| cAdvisor | 100m | 200m (pro Node) |
| **Gesamt (ca.)** | **2.45 CPU** | **10.1 CPU** |

### Memory-Anforderungen (Gesamt)

| Komponente | Requests | Limits |
|------------|----------|--------|
| Nextcloud | 512Mi | 2Gi |
| Nginx (Sidecar) | 128Mi | 256Mi |
| MariaDB | 512Mi | 2Gi |
| MySQL Exporter | 64Mi | 128Mi |
| Redis | 128Mi | 512Mi |
| Collabora | 2Gi | 4Gi |
| Prometheus | 2Gi | 4Gi |
| Grafana | 256Mi | 512Mi |
| Alertmanager | 128Mi | 256Mi |
| Node Exporter | 64Mi | 128Mi (pro Node) |
| cAdvisor | 128Mi | 256Mi (pro Node) |
| **Gesamt (ca.)** | **5.9 Gi** | **14.8 Gi** |

### Storage-Anforderungen

| Komponente | Größe | Typ |
|------------|-------|-----|
| Nextcloud Data | 50Gi | RWO |
| Nextcloud Config | 1Gi | RWO |
| MariaDB | 5Gi | RWO |
| MariaDB Backup | 5Gi | RWO |
| Prometheus | 10Gi | RWO |
| Grafana | 1Gi | RWO |
| **Gesamt** | **72 Gi** | - |

## Kontakte und Support

### Externe Ressourcen

- **Nextcloud Dokumentation:** https://docs.nextcloud.com/
- **Collabora Online:** https://www.collaboraoffice.com/code/
- **Kubernetes:** https://kubernetes.io/docs/
- **Prometheus:** https://prometheus.io/docs/
- **Grafana:** https://grafana.com/docs/

## Anhang

### Verwendete Versionen

| Software | Version |
|----------|---------|
| Nextcloud | 29.0.8 |
| MariaDB | 11.4 |
| Redis | 7-alpine |
| Collabora | 24.04.9.2.1 |
| Prometheus | 2.54.1 |
| Grafana | 11.2.2 |
| Alertmanager | 0.27.0 |
| NGINX Ingress | latest |
| cert-manager | latest |

### Änderungshistorie

| Datum | Version | Änderung | Autor |
|-------|---------|----------|-------|
| 2024-11-20 | 1.0 | Initiale Dokumentation | Lennart Schwartz |

---

**Dokumentation erstellt für:** EWE NETZ GmbH  
**Erstellt von:** Lennart Schwartz  
**Letzte Aktualisierung:** November 2024  
**Status:** Not Production Ready
