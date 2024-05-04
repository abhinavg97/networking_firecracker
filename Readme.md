Instructions:

1. Run setup_one_time.sh to install all the necessary requirements.
2. Generate ssh keys in both machines:
* ssh-keygen -t ed25519 -C "your_email@example.com"
* copy the public key of the source machine to the authorized keys file of the target machine

Note: Rest of the sections assume you are running the experiments from the source machine.

3. Install screen
- sudo apt install screen
  
4. Run the experiments in the screen:
   * bash iperf_exp.sh 1 10 10.10.1.1 192.168 192.167 

