#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <fftw3.h>

static int thread_count;

static double seconds(void)
{
	struct timespec now;

	if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
		perror("clock_gettime");
		exit(1);
	}

	return (double) now.tv_sec + (double) now.tv_nsec / 1000000000.0;
}

static void usage(const char *prog)
{
	fprintf(stderr, "Usage:\n");
	fprintf(stderr, "  %s THREADS N [iters]\n", prog);
	fprintf(stderr, "  %s THREADS <c2c|r2c|c2r|r2r> <1|2|3> N [iters]\n", prog);
	fprintf(stderr, "\n");
	fprintf(stderr, "Examples:\n");
	fprintf(stderr, "  %s 4 64 100\n", prog);
	fprintf(stderr, "  %s 8 c2c 2 256 50\n", prog);
	exit(1);
}

static void fill_real(double *x, size_t n)
{
	size_t i;
	for (i = 0; i < n; ++i) x[i] = (double) (i % 97);
}

static void fill_complex(fftw_complex *x, size_t n)
{
	size_t i;
	for (i = 0; i < n; ++i) {
		x[i][0] = (double) (i % 97);
		x[i][1] = (double) (i % 31);
	}
}

static void print_result(const char *mode, int rank, int n, int iters, double avg)
{
	if (rank == 1) {
		printf("%s 1d %d avg_seconds=%.12f iterations=%d threads=%d\n",
		       mode, n, avg, iters, thread_count);
	} else if (rank == 2) {
		printf("%s 2d %dx%d avg_seconds=%.12f iterations=%d threads=%d\n",
		       mode, n, n, avg, iters, thread_count);
	} else {
		printf("%s 3d %dx%dx%d avg_seconds=%.12f iterations=%d threads=%d\n",
		       mode, n, n, n, avg, iters, thread_count);
	}
}

static int bench_c2c(int rank, int n, int iters)
{
	int i;
	size_t total = (size_t) n;
	double t0, t1;
	fftw_complex *in;
	fftw_complex *out;
	fftw_plan p;

	if (rank == 2) total *= (size_t) n;
	if (rank == 3) total *= (size_t) n * (size_t) n;

	in = fftw_malloc(sizeof(fftw_complex) * total);
	out = fftw_malloc(sizeof(fftw_complex) * total);
	if (!in || !out) {
		fprintf(stderr, "allocation failed for c2c rank %d size %d\n", rank, n);
		fftw_free(in);
		fftw_free(out);
		return 1;
	}

	fill_complex(in, total);

	if (rank == 1) p = fftw_plan_dft_1d(n, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
	else if (rank == 2) p = fftw_plan_dft_2d(n, n, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
	else p = fftw_plan_dft_3d(n, n, n, in, out, FFTW_FORWARD, FFTW_ESTIMATE);

	if (!p) {
		fprintf(stderr, "plan creation failed for c2c rank %d size %d\n", rank, n);
		fftw_free(in);
		fftw_free(out);
		return 1;
	}

	t0 = seconds();
	for (i = 0; i < iters; ++i) fftw_execute(p);
	t1 = seconds();
	print_result("c2c", rank, n, iters, (t1 - t0) / (double) iters);

	fftw_destroy_plan(p);
	fftw_free(in);
	fftw_free(out);
	return 0;
}

static int bench_r2c(int rank, int n, int iters)
{
	int i;
	size_t in_total = (size_t) n;
	size_t out_total = (size_t) (n / 2 + 1);
	double t0, t1;
	double *in;
	fftw_complex *out;
	fftw_plan p;

	if (rank == 2) {
		in_total = (size_t) n * (size_t) n;
		out_total = (size_t) n * (size_t) (n / 2 + 1);
	} else if (rank == 3) {
		in_total = (size_t) n * (size_t) n * (size_t) n;
		out_total = (size_t) n * (size_t) n * (size_t) (n / 2 + 1);
	}

	in = fftw_malloc(sizeof(double) * in_total);
	out = fftw_malloc(sizeof(fftw_complex) * out_total);
	if (!in || !out) {
		fprintf(stderr, "allocation failed for r2c rank %d size %d\n", rank, n);
		fftw_free(in);
		fftw_free(out);
		return 1;
	}

	fill_real(in, in_total);

	if (rank == 1) p = fftw_plan_dft_r2c_1d(n, in, out, FFTW_ESTIMATE);
	else if (rank == 2) p = fftw_plan_dft_r2c_2d(n, n, in, out, FFTW_ESTIMATE);
	else p = fftw_plan_dft_r2c_3d(n, n, n, in, out, FFTW_ESTIMATE);

	if (!p) {
		fprintf(stderr, "plan creation failed for r2c rank %d size %d\n", rank, n);
		fftw_free(in);
		fftw_free(out);
		return 1;
	}

	t0 = seconds();
	for (i = 0; i < iters; ++i) fftw_execute(p);
	t1 = seconds();
	print_result("r2c", rank, n, iters, (t1 - t0) / (double) iters);

	fftw_destroy_plan(p);
	fftw_free(in);
	fftw_free(out);
	return 0;
}

static int bench_c2r(int rank, int n, int iters)
{
	int i;
	size_t in_total = (size_t) (n / 2 + 1);
	size_t out_total = (size_t) n;
	double t0, t1;
	fftw_complex *in;
	double *out;
	fftw_plan p;

	if (rank == 2) {
		in_total = (size_t) n * (size_t) (n / 2 + 1);
		out_total = (size_t) n * (size_t) n;
	} else if (rank == 3) {
		in_total = (size_t) n * (size_t) n * (size_t) (n / 2 + 1);
		out_total = (size_t) n * (size_t) n * (size_t) n;
	}

	in = fftw_malloc(sizeof(fftw_complex) * in_total);
	out = fftw_malloc(sizeof(double) * out_total);
	if (!in || !out) {
		fprintf(stderr, "allocation failed for c2r rank %d size %d\n", rank, n);
		fftw_free(in);
		fftw_free(out);
		return 1;
	}

	fill_complex(in, in_total);

	if (rank == 1) p = fftw_plan_dft_c2r_1d(n, in, out, FFTW_ESTIMATE);
	else if (rank == 2) p = fftw_plan_dft_c2r_2d(n, n, in, out, FFTW_ESTIMATE);
	else p = fftw_plan_dft_c2r_3d(n, n, n, in, out, FFTW_ESTIMATE);

	if (!p) {
		fprintf(stderr, "plan creation failed for c2r rank %d size %d\n", rank, n);
		fftw_free(in);
		fftw_free(out);
		return 1;
	}

	t0 = seconds();
	for (i = 0; i < iters; ++i) fftw_execute(p);
	t1 = seconds();
	print_result("c2r", rank, n, iters, (t1 - t0) / (double) iters);

	fftw_destroy_plan(p);
	fftw_free(in);
	fftw_free(out);
	return 0;
}

static int bench_r2r(int rank, int n, int iters)
{
	int i;
	size_t total = (size_t) n;
	double t0, t1;
	double *in;
	double *out;
	fftw_plan p;

	if (rank == 2) total *= (size_t) n;
	if (rank == 3) total *= (size_t) n * (size_t) n;

	in = fftw_malloc(sizeof(double) * total);
	out = fftw_malloc(sizeof(double) * total);
	if (!in || !out) {
		fprintf(stderr, "allocation failed for r2r rank %d size %d\n", rank, n);
		fftw_free(in);
		fftw_free(out);
		return 1;
	}

	fill_real(in, total);

	if (rank == 1) p = fftw_plan_r2r_1d(n, in, out, FFTW_REDFT10, FFTW_ESTIMATE);
	else if (rank == 2) p = fftw_plan_r2r_2d(n, n, in, out, FFTW_REDFT10, FFTW_REDFT10, FFTW_ESTIMATE);
	else p = fftw_plan_r2r_3d(n, n, n, in, out, FFTW_REDFT10, FFTW_REDFT10, FFTW_REDFT10, FFTW_ESTIMATE);

	if (!p) {
		fprintf(stderr, "plan creation failed for r2r rank %d size %d\n", rank, n);
		fftw_free(in);
		fftw_free(out);
		return 1;
	}

	t0 = seconds();
	for (i = 0; i < iters; ++i) fftw_execute(p);
	t1 = seconds();
	print_result("r2r", rank, n, iters, (t1 - t0) / (double) iters);

	fftw_destroy_plan(p);
	fftw_free(in);
	fftw_free(out);
	return 0;
}

static int run_case(const char *prog, const char *mode, int rank, int n, int iters)
{
	if (rank < 1 || rank > 3 || n <= 0 || iters <= 0) usage(prog);

	if (strcmp(mode, "c2c") == 0) return bench_c2c(rank, n, iters);
	if (strcmp(mode, "r2c") == 0) return bench_r2c(rank, n, iters);
	if (strcmp(mode, "c2r") == 0) return bench_c2r(rank, n, iters);
	if (strcmp(mode, "r2r") == 0) return bench_r2r(rank, n, iters);

	usage(prog);
	return 1;
}

static int run_all(const char *prog, int n, int iters)
{
	static const char *modes[] = { "c2c", "r2c", "c2r", "r2r" };
	size_t mode;
	int rank;

	printf("N = %d, iterations = %d, threads = %d\n", n, iters, thread_count);
	for (mode = 0; mode < sizeof(modes) / sizeof(modes[0]); ++mode) {
		for (rank = 1; rank <= 3; ++rank) {
			if (run_case(prog, modes[mode], rank, n, iters) != 0) return 1;
		}
	}

	return 0;
}

int main(int argc, char **argv)
{
	int n;
	int iters = 100;
	int status;

	if (argc < 3) usage(argv[0]);

	thread_count = atoi(argv[1]);
	if (thread_count <= 0) usage(argv[0]);

	if (!fftw_init_threads()) {
		fprintf(stderr, "FFTW thread initialization failed\n");
		return 1;
	}
	fftw_plan_with_nthreads(thread_count);

	if (argc == 3 || argc == 4) {
		n = atoi(argv[2]);
		if (argc == 4) iters = atoi(argv[3]);
		if (n <= 0 || iters <= 0) usage(argv[0]);
		status = run_all(argv[0], n, iters);
	} else if (argc == 6 || argc == 7) {
		const char *mode = argv[2];
		int rank = atoi(argv[3]);

		n = atoi(argv[4]);
		if (argc == 6) iters = atoi(argv[5]);
		if (argc == 7) usage(argv[0]);
		status = run_case(argv[0], mode, rank, n, iters);
	} else if (argc == 5) {
		const char *mode = argv[2];
		int rank = atoi(argv[3]);

		n = atoi(argv[4]);
		status = run_case(argv[0], mode, rank, n, iters);
	} else {
		usage(argv[0]);
		status = 1;
	}

	fftw_cleanup_threads();
	return status;
}
