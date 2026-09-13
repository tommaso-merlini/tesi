N = dimensione
d = rango
s = byte numero reale (complesso = 2s)

*
In più dimensioni, FFTW mantiene un array rettangolare e comprime solo l’ultimo asse:
	- 1d = N/2 + 1
	- 2d = N(N/2 + 1)
	- 3d = N^2(N/2 + 1)

	=> N^d-1 * (N/2 + 1)
*

c2c:
	- input: N^d complessi = 2sN^d
	- output: N^d complessi = 2sN^d
	- memoria: 2(2sN^d) = 4sN^d
	
r2c:
	- input: N^d reali = sN^d
	- output: N^d-1 * (N/2 + 1) complessi = 2s * N^d-1 * (N/2 + 1)
	- memoria: 2s(N^d + N^d-1)

c2r:
	- input: N^d complessi = 2sN^d
	- output: N^d-1 * (N/2 + 1) reali = s * N^d-1 * (N/2 + 1)
	- memoria: 2s(N^d + N^d-1)

r2r:
	- input: N^d reali = sN^d
	- output: N^d reali = sN^d
	- memoria: 2(sN^d) = 2sN^d

##Memoria massima utilizzata dai benchmark

risc-v:
	- threads:
		- max N = 64
		- max d = 3
		- memoria:
			- c2c:
				- double (s = 8 byte): 4sN^d = 4 * 8 * 64^3 = 8mb
			- c2r/r2c:
				- double (s = 8 byte): 2s(N^d + N^d-1) = 2*8(64^3 + 64^2) = 4mb
		=> max memoria e' c2c con 8mb
	- size:
		- max N = 1024
		- max d = 3
		- memoria:
			- c2c:
				- double (s = 8 byte): 4sN^d = 4 * 8 * 1024^3 = 32gb
			- c2r/r2c:
				- double (s = 8 byte): 2s(N^d + N^d-1) = 2*8(1024^3 + 1024^2) = 16gb
		=> max memoria e' c2c con 32gb
	- threads-size:
		- max N = 64
		- max d = 3
		- memoria:
			- c2c:
				- double (s = 8 byte): 4sN^d = 4 * 8 * 64^3 = 8mb
			- c2r/r2c:
				- double (s = 8 byte): 2s(N^d + N^d-1) = 2*8(64^3 + 64^2) = 4mb
		=> max memoria e' c2c con 8mb

x86:
	- threads:
		- max N = 64
		- max d = 3
		- memoria:
			- c2c:
				- double (s = 8 byte): 4sN^d = 4 * 8 * 64^3 = 8mb
			- c2r/r2c:
				- double (s = 8 byte): 2s(N^d + N^d-1) = 2*8(64^3 + 64^2) = 4mb
		=> max memoria e' c2c con 8mb
	- size:
		- max N = 2048
		- max d = 3
		- memoria:
			- c2c:
				- double (s = 8 byte): 4sN^d = 4 * 8 * 2048^3 = 256gb
			- c2r/r2c:
				- double (s = 8 byte): 2s(N^d + N^d-1) = 2*8(2048^3 + 2048^2) = 128gb
		=> max memoria e' c2c con 256gb
	- threads-size:
		- max N = 64
		- max d = 3
		- memoria:
			- c2c:
				- double (s = 8 byte): 4sN^d = 4 * 8 * 64^3 = 8mb
			- c2r/r2c:
				- double (s = 8 byte): 2s(N^d + N^d-1) = 2*8(64^3 + 64^2) = 4mb
		=> max memoria e' c2c con 8mb

arm:
	- threads:
		- max N = 64
		- max d = 3
		- memoria:
			- c2c:
				- double (s = 8 byte): 4sN^d = 4 * 8 * 64^3 = 8mb
			- c2r/r2c:
				- double (s = 8 byte): 2s(N^d + N^d-1) = 2*8(64^3 + 64^2) = 4mb
		=> max memoria e' c2c con 8mb
	- size:
		- max N = 1024
		- max d = 3
		- memoria:
			- c2c:
				- double (s = 8 byte): 4sN^d = 4 * 8 * 1024^3 = 32gb
			- c2r/r2c:
				- double (s = 8 byte): 2s(N^d + N^d-1) = 2*8(1024^3 + 1024^2) = 16gb
		=> max memoria e' c2c con 32gb
	- threads-size:
		- max N = 64
		- max d = 3
		- memoria:
			- c2c:
				- double (s = 8 byte): 4sN^d = 4 * 8 * 64^3 = 8mb
			- c2r/r2c:
				- double (s = 8 byte): 2s(N^d + N^d-1) = 2*8(64^3 + 64^2) = 4mb
		=> max memoria e' c2c con 8mb
