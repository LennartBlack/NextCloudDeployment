kubectl get pods
kubectl exec -it nextcloud-5b586ccb66-494bg -n nextcloud -- /bin/bash
kubectl exec -it nextcloud-5b586ccb66-494bg -n nextcloud -- bash -c "su -s /bin/bash -c 'php occ encryption:status' #1000"
kubectl exec -u 1000 -it nextcloud-5b586ccb66-494bg -n nextcloud -- php occ encryption:status
exit
kubectl exec -u 1000 -it nextcloud-5b586ccb66-494bg -n nextcloud -- php occ encryption:status
clear
ls -l config/config.php
kubectl exec -it nextcloud-5b586ccb66-494bg -n nextcloud -- bash
kubectl exec -u 1000 -it nextcloud-5b586ccb66-494bg -n nextcloud -- php occ encryption:status
getent passwd 1000
su -s /bin/bash -c 'php occ encryption:status' nextcloud
chown www-data:www-data config/config.php
su -s /bin/bash -c 'php occ encryption:status' www-data
# Optionally change it back after
chown 1000:www-data config/config.php
su -s /bin/bash -c 'php occ encryption:status' cloudshell-user
su -s /bin/bash -c 'php occ encryption:status' 1000
su -s /bin/bash -c 'php occ encryption:status' cloudshell-user
cat /etc/passwd
php occ encryption:status
su -s /bin/bash -c 'php occ encryption:status' cloudshell-user
passwd cloudshell-user
vi /etc/passwd
ls
cat deployment.yaml
grep -rin resources .
grep -nH resources *.yaml
cat pvc.yaml
cat statefulset-mariadb.yaml
cat talk-hpb-deployment.yaml
cat deployment.yaml
nano deployment.yaml
kubectl apply -f deployment.yaml
kubectl get pods
kubectl get services
ls
nano ingress.yaml
kubectl get pods
kubectl exec -it nextcloud-cf5d59949-9bnh5 -n nextcloud -- /bin/bash
kubectl get pods
kubectl exec -it nextcloud-cf5d59949-9bnh5 --user 1000 -- php occ maintenance:repair
exit
