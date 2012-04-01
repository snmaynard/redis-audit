#redis-audit

This script samples a set of the redis keys in a database and then groups those keys into groups of similar looking keys. It then displays key 
metrics around those keys to help you spot where efficiencies can be made in the memory usage of redis.

##Usage
  redis-audit.rb <host> <port> <dbnum> <sample_size>

##Outputs
  Auditing 127.0.0.1:6379 db:3 sampling 26000 keys
  DB has 8951491 keys
  Sampled 32.88 MB of redis memory

  Found 2 key groups

  ==============================================================================
  Found 10000 keys containing strings, like:
  user_profile_3897016, user_profile_3339430, user_profile_3240266, user_profile_2883394, user_profile_3969781, user_profile_3256693, user_profile_3766796, user_profile_2051997, user_profile_2817842, user_profile_1453480

  These keys use 11.86% of the total sampled memory (3.9 MB)
  99.98% of these keys expire (10067), with maximum ttl of 4 days, 23 hours, 59 minutes, 44 seconds
  Average idle time: 1 days, 8 hours, 27 minutes, 56 seconds - (Max: 12 days, 20 hours, 13 minutes Min:20 seconds)

  ==============================================================================
  Found 16000 keys containing zsets, like:
  notification_3109439, notification_3634040, notification_2318378, notification_3871169, notification_3980323, notification_3427141, notification_1639845, notification_2823390, notification_2658377, notification_4153039

  These keys use 88.14% of the total sampled memory (28.98 MB)
  None of these keys expire
  Average idle time: 10 days, 6 hours, 13 minutes, 23 seconds - (Max: 12 days, 20 hours, 13 minutes, 10 seconds Min:2 minutes)

##Key Grouping Algorithm
The key grouping algorithm is a good default, but you may require more control over it. There is an array of regular expressions (@@key_group_regex_list) that can be used to help force a group.
If the key being sampled matches a regular expression, it is grouped with all the keys that match that regex.