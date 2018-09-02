#!/bin/sh

# Create empty databse for second instance of crp website in ~merlyn/crp2

echo
echo "-- Dropping and recreating DB"
su - postgres postgres -c "psql -U postgres -c \"drop database crp2\""
su - postgres postgres -c "dropuser crp2"
su - postgres postgres -c "createuser crp2 -SdR"
su - postgres postgres -c "psql -U postgres -d postgres -c \"alter user crp2 with password 'cr12114';\""
su - postgres postgres -c "psql -U postgres -c \"create database crp2 with owner = crp2;\""

echo
echo "-- Fixing config"
cd ~merlyn/crp2
sed -i -e "s/username    => 'crp',/username    => 'crp2',/" c_r_p.conf
sed -i -e "s/dbname      => 'crp',/dbname      => 'crp2',/" c_r_p.conf
sed -i -e "s/'Automated system/'CRP2 Automated system/" c_r_p.conf

echo
echo "-- Initialising DB schema"
carton exec ./script/crp migrate install

echo
echo "-- Creating default user account"
# User with the passowrd "Wordpass1"
su - postgres -c "psql -U crp2 -c \"insert into login (email, password_hash, is_administrator) values ('sue@susanquayle.co.uk', '3800ae146dae50e2ea10f45020952391', true);\""

echo
echo "-- Removing uploaded OLC content"
rm -rf public/olc/images/uploaded/*
rm -rf public/olc/video-thumbs/uploaded/*
rm -rf videos/olc/uploaded/*
rm -rf pdfs/olc/uploaded/*

echo
echo "-- Done"
