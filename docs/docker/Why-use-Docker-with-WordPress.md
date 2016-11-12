# Why Use Docker with WordPress?

## Security

### Malware

WordPress sites are often hacked. Often the issue is not core WP but instead an insecure plugin, like for instance recently it was Gravity forms. Once a site is hacked, it then has to be cleaned up. Malware can infect all files on all sites owned by the same Unix user. Companies like Sucuri or Sitelock focus on monitoring for such hacks and provide remediation services to clean up the site once the site is hacked. They encourage users to keep their sites updated, but often this is not enough as the vunerability is discovered after it has been used to exploit many sites. Docker helps by isolating each site in its container, keeping the malware confined to a single exploited site. There are other methods of doing this, like Chroot, but Docker makes this trivial.

### Data theft

Once a site is exploited, all data on the site is available for the attacker to download. If multiple sites are running on the same server with the same user, say www-data, or the same group with the wrong file permissions. Then all data for all sites can be accessed by the attacker. This allows the attacked to steal hashed passwords, private information, usernames or anything else that might be of value and is accessible by the user. That can then later be used to attack yet other sites and deface them, steal e-mails, and so on.


### Loss of search engine ranking

Exploited sites may produce different content which could cause your listing to lose rank. They may also host malware which is served to desktop comuputers. If a site is compromised then it's very likely that Google will detect this and unlsit your site until you remedy the problem. That means loss of traffic and therefore loss of business for your site. 

## Performance

Load Impact profiled Docker against bare metal, meaning servers without any virtualization, and found near bare metal performance using Docker. They generally found performance of Docker vs. Bare Metal was very similar. You pay a small penalty for using Docker rather than bare metal, but the benefits of added security and isolation more than makes up for this short coming.

- http://blog.loadimpact.com/blog/wordpress-bare-metal-vs-wordpress-docker-performance-comparison/


## Maintainace and Upgrading Containers
See [Maintainace and Upgrading](/docker/Upgrading-Containers)