#Redis-audit

This script samples a number of the Redis keys in a database and then groups them with other *similar* looking keys. It then displays key 
metrics around those groups of keys to help you spot where efficiencies can be made in the memory usage of your Redis database.

##Example

If you have a Redis database that contains two sets of keys "user\_profile\_#{user\_id}" and "notification\_#{user\_id}", this script will
help you work out which group of keys is taking up more memory. It will also help you spot keys that should have an expiry that don't, as well
as providing you with statistics on how often keys are accessed within each group.

##Usage
  redis-audit.rb [host] [port] [dbnum] [sample_size]

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

##Key Grouping Algorithm
The key grouping algorithm is a good default, but you may require more control over it. There is an array of regular expressions that can be used to help force a group.
If the key being sampled matches a regular expression, it is grouped with all the keys that match that regex.

  @@key_group_regex_list = [/notification/,/user_profile/]
  
##Other Redis Audit Tools
- [Redis Sampler](https://github.com/antirez/redis-sampler) - Samples keys for statistics around how often you each Redis value type, and how big the value is. By Antirez.