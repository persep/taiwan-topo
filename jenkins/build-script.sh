build=NG
instance=ttb-hd
[ -z "$DROPBOX" ] && DROPBOX=/var/shared/Dropbox

## start Google GCE for taiwan topo building
gcloud compute instances start ${instance}
for i in 1 2 3; do 
  gcloud compute ssh --command="~/bin/build.sh" rudychung@${instance} && build=OK && break
  
  ## failed, let's retry
  gcloud compute instances stop ${instance}
  sleep $((i*60))
  gcloud compute instances start ${instance}
done || echo "Failed after retry 3 times."

gcloud compute instances stop ${instance}


## Deploy to Dropbox
[ "${build}" = "OK" ] || exit 1

VERSION=$(date +%Y.%m.%d)
GS_FILENAME="dayofmonth_$(date +%d)"

gsutil cp gs://osm-twmap-drops/${GS_FILENAME}.tgz .
tar xzf ${GS_FILENAME}.tgz
cp -r v${VERSION}/* $DROPBOX/Public/drops/  ### daily drops

[ "$(date +%w)" -eq 4 ] && {  ### weekly drops
  cp -r v${VERSION}/* $DROPBOX/Public/maps/
  cp -r v${VERSION}/MOI_OSM_Taiwan_TOPO_Rudy* $DROPBOX/Apps/share-mapdata/
  echo "Completed with weeekly drop."
}  || echo "Completed without weekly drop."