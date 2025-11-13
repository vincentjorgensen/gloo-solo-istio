# Root cert
mkdir certs
cd certs
make -f ../tools/certs/Makefile.selfsigned.mk root-ca

# Then for each subsequent cluster that you want to share the same root:
make -f ../tools/certs/Makefile.selfsigned.mk cluster1-cacerts
make -f ../tools/certs/Makefile.selfsigned.mk cluster2-cacerts
make -f ../tools/certs/Makefile.selfsigned.mk cluster3-cacerts
