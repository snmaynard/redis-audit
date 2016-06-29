#Redis-audit

This script samples a number of the Redis keys in a database and then groups them with other *similar* looking keys. It then displays key 
metrics around those groups of keys to help you spot where efficiencies can be made in the memory usage of your Redis database.  
_Warning_: The script cannot be used with AWS Elasticache Redis instances, as the debug command is restricted.

##Installation
   `bundle install` will take care of everything!


##Example

If you have a Redis database that contains two sets of keys "user\_profile\_#{user\_id}" and "notification\_#{user\_id}", this script will
help you work out which group of keys is taking up more memory. It will also help you spot keys that should have an expiry that don't, as well
as providing you with statistics on how often keys are accessed within each group.

##Usage

The script provides two different methods of being run, one with argument decleration and a legacy method based on order of the arguments passed in.    

The legacy option looks like this:

    redis-audit.rb [host] [port] [password] [dbnum] [(optional)sample_size]

You can also specify the arguments with declarations, which also adds the ability to use a Redis URL and pass in authentication credentials:

    redis-audit.rb -h/--host [host] -p/--port [port] -a/--password [password] -d/--dbnum [dbnum] -s/--sample [(optional)sample_size]
    
    or
    
    redis-audit.rb -u/--url [url] -s/--sample [(optional)sample_size]
  
- **Host**: Generally this is 127.0.0.1 (Please note, running it remotely will cause the script to take significantly longer)
- **Port**: The port to connect to (e.g. 6379)
- **Password**: The Redis password if authentication is required
- **DBNum**: The Redis database to connect to (e.g. 0)
- **Sample size**: This optional parameter controls how many keys to sample. I recommend starting with 10, then going to 100 initially. This
will enable you to see that keys are being grouped properly. If you omit this parameter the script samples 10% of your keys. If the sample size is
greater than the number of keys in the database the script will walk all the keys in the Redis database. **DO NOT** run this with a lot of keys on 
a production master database. Keys * will block for a long time and cause timeouts!
- **Url**: Follows the normal syntax for Redis Urls

`redis-audit.rb --help` will print out the argument options as well.

##Outputs
    Auditing 127.0.0.1:6379 db:0 sampling 26000 keys
    DB has 8951491 keys
    Sampled 32.88 MB of Redis memory

    Found 2 key groups

    ==============================================================================  
    Found 10000 keys containing strings, like:  
    user_profile_3897016, user_profile_3339430, user_profile_3240266, user_profile_2883394, user_profile_3969781, user_profile_3256693, user_profile_3766796, user_profile_2051997, user_profile_2817842, user_profile_1453480

    These keys use 11.86% of the total sampled memory (3.9 MB)  
    99.98% of these keys expire (10067), with maximum ttl of 4 days, 23 hours, 59 minutes, 44 seconds  
    Average last accessed time: 1 days, 8 hours, 27 minutes, 56 seconds - (Max: 12 days, 20 hours, 13 minutes Min:20 seconds)  

    ==============================================================================  
    Found 16000 keys containing zsets, like:  
    notification_3109439, notification_3634040, notification_2318378, notification_3871169, notification_3980323, notification_3427141, notification_1639845, notification_2823390, notification_2658377, notification_4153039

    These keys use 88.14% of the total sampled memory (28.98 MB)  
    None of these keys expire  
    Average last accessed time: 10 days, 6 hours, 13 minutes, 23 seconds - (Max: 12 days, 20 hours, 13 minutes, 10 seconds Min:2 minutes)  
  
    ==============================================================================  
    Summary  
  
    ---------------------------------------------------+--------------+-------------------+---------------------------------------------------  
    Key                                                | Memory Usage | Expiry Proportion | Last Access Time                                    
    ---------------------------------------------------+--------------+-------------------+---------------------------------------------------  
    notification_3109439                               | 88.14%       | 0.0%              | 2 minutes                               
    user_profile_3897016                               | 11.86%       | 99.98%            | 20 seconds  
    ---------------------------------------------------+--------------+-------------------+---------------------------------------------------  

##Key Grouping Algorithm
The key grouping algorithm is a good default, but you may require more control over it. There is an array of regular expressions that can be used to help force a group.
If the key being sampled matches a regular expression, it is grouped with all the keys that match that regex.

    @@key_group_regex_list = [/notification/,/user_profile/]

If you don't configure the regular expressions, the script has to find a good match for each key that it finds, which can
take a significant amount of time, depending on the number of types of keys. If you find the script takes too long to run, 
I recommend setting up the regular expressions. Even if you only set the regular expressions for 50% of the keys it will encounter,
the speedup will still be noticeable.

**Please note:** If your keys are appended with a namespace, rather than prepended, then you will have to configure a full set
of regular expressions.

##Memory Usage
The memory usage that the script calculates is based on the serialized length as reported by Redis using the DEBUG OBJECT command.
This memory usage is not equal to the resident memory taken by the key, but is (hopefully) proportional to it.
  
##Other Redis Audit Tools
- [Redis Sampler](https://github.com/antirez/redis-sampler) - Samples keys for statistics around how often you each Redis value type, and how big the value is. By Antirez.
