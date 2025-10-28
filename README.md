Skrypt na starym (zsynchronizowanym) nodzie — make-bootstrap.sh

	•	Zatrzymuje kontener na chwilę
	•	Pakuje tylko chain_data_dir (bez node-key)
	•	Uruchamia kontener ponownie
	•	Zapisuje snapshot z datą i sumą SHA256
	•	Podpowiada komendę scp

  Użycie (na starym nodzie):

  chmod +x make-bootstrap.sh
./make-bootstrap.sh

lub

./make-bootstrap.sh /root/quantus /root quantus-C01

/root/bootstrap-quantus-schrodinger-2025xxxx-xxxxxx.tar.gz

/root/bootstrap-quantus-schrodinger-2025xxxx-xxxxxx.tar.gz.sha256


2) Skrypt na nowym nodzie — „import” snapshotu (import-bootstrap.sh)

  •	Weryfikuje SHA256 (jeśli podasz plik .sha256)
	•	Rozpakowuje chain_data_dir do katalogu z binarkami
	•	Nie dotyka node-key (zostanie wygenerowany przy starcie przez Twój run-skrypt)





