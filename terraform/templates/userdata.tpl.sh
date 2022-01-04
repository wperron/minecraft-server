#!/bin/bash
echo "LOKI_USERNAME=${loki_username}" > vector
echo "LOKI_PASSWORD=${loki_password}" >> vector
echo "PROM_USERNAME=${prom_username}" >> vector
echo "PROM_PASSWORD=${prom_password}" >> vector
sudo mv vector /etc/default/vector

sudo systemctl restart minecraft.service
sudo systemctl restart minecraft_exporter.service
sudo systemctl restart vector.service