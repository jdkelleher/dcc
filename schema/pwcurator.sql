# mysql -p

create database pwcurator;

create user 'pwcadmin'@'localhost' identified by 'changeme';
create user 'pwcdaemon'@'localhost' identified by 'changeme';
create user 'readonly'@'localhost' identified by 'readonly';

grant ALL on pwcurator.* to 'pwcadmin'@'localhost'; 
grant select on pwcurator.* to 'pwcdaemon'@'localhost'; 
grant select on pwcurator.* to 'readonly'@'localhost'; 

connect pwcurator;


# credentials and metadata, 
# ie passwords, crypto keys, communities
# and descriptions, signatures, etc
create table creds (
    # serial id number for joins
    cid int not null unique primary key auto_increment,
    # name of credential
    name varchar(128) not null unique,
    # text description/comment
    descrip varchar(256) not null default '',
    # encrypted credential blob
    enccred varchar(8106) not null default '',
    # signature of encrypted credential blob
    # so we know if an attacker altered this DB
    sig varchar(2048) not null default '',
    # credential is inner-outer encrypted
    needs_inner_key boolean not null default false,
    # is this credential administratively enabled?
    enabled boolean not null default true,
    modified datetime not null default now()
    );
grant all on creds to pwcadmin@localhost;
grant select on creds to pwcdaemon@localhost;
grant select on creds to readonly@localhost;




# client hosts
create table hosts (
    # serial id number for joins
    hid int not null unique primary key auto_increment,
    # host name or ip of client
    host varchar(128) not null unique,
    # text description/comment
    descrip varchar(256) not null default '',
    # client host's public x509 certificate 
    pubcrt varchar(2048) not null default '',
    # signature of pubcrt
    # so we know if an attacker altered this DB
    sig varchar(2048) not null default '',
    # is this client host administratively enabled?
    enabled boolean not null default true,
    modified datetime not null default now()
    );
grant all on hosts to pwcadmin@localhost;
grant select on hosts to pwcdaemon@localhost;
grant select on hosts to readonly@localhost;

# create wildcard host
insert into hosts ( host, description, sig, modified ) 
    values ( '*', 'any host', '', now() );




# access control lists
create table acls (
    # serial id number for joins
    aid int not null unique primary key auto_increment,
    # serial id of credential this acl applies to
    aid int not null references creds( cid ),
    # serial id of client host that's allowed, might be the * host
    hid int not null references hosts( hid ),
    # text description/comment
    descrip varchar(256) not null default '',
    # username on host this acl applies to
    username varchar(128) not null,
    # signature of this acl
    # so we know if an attacker altered this DB
    sig varchar(2048) not null default '',
    # is this acl administratively enabled?
    enabled boolean not null default true,
    modified datetime not null default now()
    );
grant all on acls to pwadmin@localhost;
grant select on acls to pwcdaemon@localhost;
grant select on acls to readonly@localhost;





# request log
create table log (
    when datetime not null default now(),
    # serial id of credential this acl applies to
    aid int not null,
    # serial id of client host that's allowed, might be the * host
    hid int not null,
    # acl serial id number 
    aid int not null,
    # recorded credential name 
    name varchar(128) not null,
    # recorded client hostname 
    host varchar(128) not null,
    # recorded username on host
    username varchar(128) not null,
    # text description/comment
    comment varchar(1024) not null default '',
    # result we sent, ie 200 ok, or 403 forbidden, see rfc2616
    result int not null default 0,
    # signature of this log row
    # so we know if an attacker altered this DB
    sig varchar(2048) not null default ''
    );
grant all on log to pwadmin@localhost;
grant select, insert on log to pwcdaemon@localhost;
grant select on log to readonly@localhost;





