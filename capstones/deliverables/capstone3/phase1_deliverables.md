# Phase 1 Deliverables: The Manual Build (Console Simulation) 📸

Dokumen ini berisi daftar resource yang telah dibuat selama Phase 1 sebagai simulasi lingkungan _legacy_. Silakan lampirkan tangkapan layar (screenshot) dari AWS Management Console untuk setiap poin di bawah ini.

---

## 1. Networking (VPC & Subnets)

Pastikan Nama dan CIDR sesuai dengan standar yang didefinisikan dalam [Project_Capstone_Import.md](../../capstone3/Project_Capstone_Import.md).

### 1.1 Dev Environment

- [ ] **VPC**: Tangkapan layar daftar VPC yang memperlihatkan `dev-vpc` (10.0.0.0/16).
      ![alt text](assets/image.png)
      ![alt text](assets/image-2.png)
- [ ] **Subnets**: Tangkapan layar daftar Subnet yang memperlihatkan 2 Public Subnets dan 2 Private Subnets.
      ![alt text](assets/image-3.png)
- [ ] **NAT Gateway**: Tangkapan layar detail `dev-nat-gw` yang menunjukkan status `Available` dan terhubung ke EIP.
      ![alt text](assets/image-6.png)

### 1.2 Prod Environment

- [ ] **VPC**: Tangkapan layar daftar VPC yang memperlihatkan `prod-vpc` (10.1.0.0/16).
      ![alt text](assets/image-5.png)
- [ ] **Subnets**: Tangkapan layar daftar Subnet (Public A/B, Private A/B).
      ![alt text](assets/image-4.png)
- [ ] **NAT Gateway**: Tangkapan layar detail `prod-nat-gw`.
      ![alt text](assets/image-7.png)

---

## 2. Compute (EC2 Instances)

Screenshot detail instance yang menampilkan: **Instance**.

- [ ] **web-dev**: Berlokasi di `dev-private-subnet-a`.
      ![alt text](assets/image-8.png)
- [ ] **web-prod**: Berlokasi di `prod-private-subnet-a`.
      ![alt text](assets/image-9.png)
- [ ] **User Data Verification**: (Opsional) Hasil akses HTTP ke ALB DNS yang menampilkan pesan _"<h1>Capstone [ENV] Server...</h1>"_.
      ![alt text](assets/image-10.png)![alt text](assets/image-11.png)

---

## 3. Load Balancing (ALB & NLB)

Screenshot yang menunjukkan rantai konektivitas: **NLB (Static IP) -> ALB (Multi-AZ) -> EC2**.

### 3.1 Application Load Balancer (ALB)

- [ ] **Load Balancer**: Detail `capstone-dev-alb` dan `capstone-prod-alb`.
      ![alt text](assets/image-12.png)
      ![alt text](assets/image-13.png)
      ![alt text](assets/image-14.png)
      ![alt text](assets/image-15.png)
- [ ] **Target Groups**: `capstone-dev-ec2-tg` menunjukkan target (EC2) berstatus `Healthy`.
      ![alt text](assets/image-16.png)
      ![alt text](assets/image-17.png)

### 3.2 Network Load Balancer (NLB)

- [ ] **Load Balancer**: Detail `capstone-dev-nlb` yang menunjukkan penggunaan ELastic IP.
      ![alt text](assets/image-18.png)
      ![alt text](assets/image-19.png)
      ![alt text](assets/image-20.png)
      ![alt text](assets/image-21.png)
- [ ] **Target Groups**: `capstone-dev-alb-tg` menunjukkan target berupa ALB berstatus `Healthy`.
      ![alt text](assets/image-22.png)
      ![alt text](assets/image-23.png)

---

## 4. Storage (S3 Buckets)

Screenshot daftar bucket yang memperlihatkan pengaturan keamanan.

- [ ] **Dev Bucket**: `capstone-dev-[yourname]-[random]`
      ![alt text](assets/image-24.png)
- [ ] **Prod Bucket**: `capstone-prod-[yourname]-[random]`
      ![alt text](assets/image-25.png)

- [ ] **State Bucket**: `capstone-tfstate-[yourname]-[random]`
      ![alt text](assets/image-26.png)

- [ ] **Security Settings**: Screenshot yang menunjukkan:
  - **Versioning**: Enabled
  - **Encryption**: AES-256
  - **Public Access**: Block All
    ![alt text](assets/image-27.png)
    ![alt text](assets/image-28.png)
    ![alt text](assets/image-29.png)
    ![alt text](assets/image-30.png)
    ![alt text](assets/image-31.png)
    ![alt text](assets/image-32.png)

---

## 5. Security Configuration

- [ ] **Security Groups**:
  - `capstone-[env]-alb-sg`: Inbound HTTP (80) dari `0.0.0.0/0`.
    ![alt text](assets/image-33.png)
    ![alt text](assets/image-34.png)
  - `capstone-[env]-ec2-sg`: Inbound HTTP (80) dari source SG ALB.
    ![alt text](assets/image-36.png)
    ![alt text](assets/image-37.png)

---
