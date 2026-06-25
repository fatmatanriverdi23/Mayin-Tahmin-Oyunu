# Mayın Tahmin Oyunu (16-bit Assembly Minesweeper)

Bu proje, mikroişlemciler ve Assembly dili prensiplerini uygulamalı olarak göstermek amacıyla sıfırdan geliştirilmiş bir "Mayın Tarlası" (Minesweeper) simülasyonudur.
Emu8086 simülatörü üzerinde çalışacak şekilde 16-bit x86 Assembly mimarisi kullanılarak yazılmıştır. 

Yüksek seviyeli programlama dillerinde kolayca yapılabilen matris yönetimi, özyinelemeli fonksiyonlar ve ekrana çizim işlemlerinin, doğrudan bellek adresleri ve register'lar kullanılarak donanıma en yakın seviyede nasıl inşa edildiğini göstermeyi amaçlamaktadır.

##  Temel Özellikler

* **Gelişmiş Bellek Yönetimi (Direct Memory Access):** Oyun ekranı ve grafikler doğrudan Video RAM (0B800h) üzerine ofset hesaplamalarıyla yazılarak oluşturulmuştur.
* **Özyinelemeli (Recursive) Algoritma:** Etrafında mayın olmayan (0 değerli) bir boş hücre açıldığında, `open_recursive` fonksiyonu Stack (Yığın) yapısını (PUSH/POP) kullanarak bağlı tüm güvenli alanları zincirleme olarak tek hamlede açar.
* **Hızlı Yeniden Başlatma (VRAM Snapshot):** Oyun ilk açıldığında belleğe (`backup` dizisine) kaydedilen 4000 byte'lık taptaze ekran görüntüsü yedeği sayesinde, oyun bittiğinde `REP MOVSW` komutuyla saliseler içinde ekran sıfırlanarak yeni oyuna geçilir.
* **Rastgele Mayın Yerleşimi:** Sistem saatinden alınan "Seed" değeri ve LCG (Linear Congruential Generator) algoritması ile 10x7'lik haritaya her oyun başlangıcında rastgele 14 adet mayın yerleştirilir.

##  Kullanılan Teknolojiler ve Kesmeler (Interrupts)

* **Mimari:** 16-bit x86 Assembly (Emu8086)
* **Video Servisleri (`INT 10h`):** Ekranı temizlemek (AX=0003h), grafik modunu ayarlamak ve renkli ASCII karakterlerini ekrana basmak için kullanılmıştır.
* **Klavye Servisleri (`INT 16h`):** Kullanıcının tuş vuruşlarını (girdi/input) asenkron olarak yakalamak (AH=00h) için kullanılmıştır.
* **Zamanlayıcı Servisleri (`INT 1Ah`):** Rastgele mayın yerleşimi için sistem saatinden referans almak amacıyla kullanılmıştır.

##  Oyun Kuralları ve Kontroller

Oyun, 10x7 boyutlarındaki bir grid (ızgara) üzerinde oynanır ve başlangıçta oyuncuya 3 can (kalp) verilir. 

### Kontroller
* **Ok Tuşları:** Harita üzerindeki gri vurgulu imleci hareket ettirir.
* **ENTER:** İmlecin bulunduğu kapalı kutuyu açar.
* **F Tuşu:** Mayın olduğundan şüphelenilen kutuya bayrak (►) koyar veya var olan bayrağı kaldırır.
* **R Tuşu:** Oyun bittiğinde haritayı ve istatistikleri sıfırlayarak oyunu hızlıca yeniden başlatır.

### Ekran Sembolleri
* **Sayılar (1-8):** Açılan kutunun etrafındaki yatay, dikey ve çapraz 8 komşu hücrede toplam kaç adet mayın olduğunu gösterir.
* **Boş Kutular (0):** Çevresinde hiç mayın olmayan güvenli bölgelerdir.
* **Bayrak (►):** Oyuncunun mayın olduğunu tahmin ettiği yerlere koyduğu işarettir.
* **Mayın (☼):** Yanlışlıkla basıldığında patlayan ve oyuncuya bir can kaybettiren (skoru 100 azaltan) gizli tehlikedir.

### Kazanma ve Kaybetme Koşulları
* **Kazanma:** Haritadaki 14 mayının tamamının yeri doğru tespit edilip üzerlerine bayrak konulduğunda (mayın sayacı 0'a düştüğünde) oyun kazanılır ve ekranda yeşil renkte "YOU WIN! ☺" mesajı çıkar.
* **Kaybetme:** Mayınlı bir hücreye basılarak toplamda 3 can kaybedildiğinde oyun kaybedilir, tüm gizli mayınlar görünür hale gelir ve kırmızı bir uyarıyla ("GAME OVER!") oyun durur.
