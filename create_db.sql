create table cn(
can_id VARCHAR(9) PRIMARY KEY,
f_name VARCHAR(38),
l_name VARCHAR(38),
party1 VARCHAR(3),
party3 VARCHAR(3),
incumb VARCHAR(1),
can_status VARCHAR(1),
street1 VARCHAR(34),
street2 VARCHAR(34),
city VARCHAR(18),
zipcode VARCHAR(5),
camp_comm_id VARCHAR(9),
elect_yr VARCHAR(2),
curr_district VARCHAR(2)
);

create table cm(
comm_id VARCHAR(9),
comm_name VARCHAR(90),
treas_f_name VARCHAR(38),
treas_l_name VARCHAR(38),
street1 VARCHAR(34),
street2 VARCHAR(34),
city VARCHAR(18),
state VARCHAR(2),
zipcode VARCHAR(5),
comm_des VARCHAR(1),
comm_type VARCHAR(1),
comm_party VARCHAR(3),
file_freq VARCHAR(1),
interest_grp_cat VARCHAR(38),
can_id VARCHAR(9)
);

create table oth(
filer_id VARCHAR(9),
amd_indic VARCHAR(1),
report_type VARCHAR(3),
pri_indic VARCHAR(1),
micro_film VARCHAR(11),
trans_type VARCHAR(3),
oth_name VARCHAR(34),
city VARCHAR(18),
state VARCHAR(2),
zipcode VARCHAR(5),
employer VARCHAR(35),
job_title VARCHAR(35),
trans_month VARCHAR(2),
trans_day VARCHAR(2),
trans_cent VARCHAR(2),
trans_yr VARCHAR(2),
amt MEDIUMINT(7),
other_id VARCHAR(9),
fec_num VARCHAR(7)
);

create table pas2(
filer_id VARCHAR(9),
amd_indic VARCHAR(1),
report_type VARCHAR(3),
pri_indic VARCHAR(1),
micro_film VARCHAR(11),
trans_type VARCHAR(3),
trans_month VARCHAR(2),
trans_day VARCHAR(2),
trans_cent VARCHAR(2),
trans_yr VARCHAR(2),
amt MEDIUMINT(7),
other_id VARCHAR(9),
fec_num VARCHAR(7)
);

create table indiv(
filer_id VARCHAR(9),
amd_indic VARCHAR(1),
report_type VARCHAR(3),
pri_indic VARCHAR(1),
micro_film VARCHAR(11),
trans_type VARCHAR(3),
f_name VARCHAR(34),
l_name VARCHAR(34),
city VARCHAR(18),
state VARCHAR(2),
zipcode VARCHAR(5),
employer VARCHAR(35),
job_title VARCHAR(35),
trans_month VARCHAR(2),
trans_day VARCHAR(2),
trans_cent VARCHAR(2),
trans_yr VARCHAR(2),
amt MEDIUMINT(7),
other_id VARCHAR(9),
fec_num VARCHAR(7)
);