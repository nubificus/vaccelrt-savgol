#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <vaccel.h>

struct vaccel_prof_region savgol_op_stats =
        VACCEL_PROF_REGION_INIT("vaccel_savgol");


#define CHUNK 4096
int fileread_from_stdin(char**ptr, ssize_t *len)
{
        char buf[CHUNK];
        int ret = 0;
        int size = 0;
        char *p = malloc(CHUNK);
        while ((ret = read (STDIN_FILENO, buf, CHUNK)) > 0) {
                size += ret;
                p = realloc(p, size);
                memcpy(p+(size - ret), buf, ret);
        }
        //write(STDOUT_FILENO, p, size);
        *ptr = p;
        *len = size;

        return 0;
}

int read_file(const char *filename, char **img, size_t *img_size)
{
        int fd;
        long bytes = 0;

        fd = open(filename, O_RDONLY);
        if (fd < 0) {
                perror("open: ");
                return 1;
        }

        struct stat info;
        fstat(fd, &info);
        fprintf(stdout, "File size: %luB\n", info.st_size);

        char *buf = (char*)malloc(info.st_size + 1);
        if (!buf) {
                fprintf(stderr, "Could not allocate memory for image\n");
                goto close_file;
        }

        do {
                int ret = read(fd, buf, info.st_size);
                if (ret < 0) {
                        perror("Error while reading image: ");
                        goto free_buff;
                }
                bytes += ret;
        } while (bytes < info.st_size);

        if (bytes < info.st_size) {
                fprintf(stderr, "Could not read image\n");
                goto free_buff;
        }

        buf[info.st_size] = '\0';
        *img = buf;
        *img_size = info.st_size + 1;
        close(fd);

        return 0;

free_buff:
        free(buf);
close_file:
        close(fd);
        return 1;
}

int savgol_GPU_vaccel(int argc, char ** argv)
{

        int ret = 0, i = 0;
        struct vaccel_session sess;
        struct vaccel_arg args[4];
        double time1, time2;
	size_t file_size;
        char *file;

	//printf("filename: %s\n", argv[1]);
#if 0
        if (read_file(argv[1], &file, &file_size))
                return 1;
#endif
        if (fileread_from_stdin(&file, &file_size))
                return 1;

	char * output = malloc(file_size);
        vaccel_prof_region_start(&savgol_op_stats);

        ret = vaccel_sess_init(&sess, 0);
        if (ret != VACCEL_OK) {
                fprintf(stderr, "Could not initialize session\n");
                return 1;
        }

        printf("Initialized session with id: %u\n", sess.session_id);


        char operation[256] = "savgol_GPU_unpack";
        char library[512];
        sprintf(library, "/usr/local/lib/libsavgol_cuda.so");

        memset(args, 0, sizeof(args));
        args[0].size = file_size;
        args[0].buf = file;

        args[1].size = sizeof(double);
        args[1].buf = &time1;
        args[2].size = sizeof(double);
        args[2].buf = &time2;
        args[3].size = file_size;
        args[3].buf = output;

	printf("args[3].size: %d\n", args[3].size);
	printf("total numbers: %d\n", args[3].size/sizeof(double));

        printf("Host library: %s\n", library);
        printf("Operation: %s\n", operation);
        ret = vaccel_exec(&sess, library, operation, &args[0], 1, &args[1], 3);
        if (ret) {
                fprintf(stderr, "Could not run op: %d\n", ret);
                goto close_session;
        }

        printf("GPU process time:%lf Savgol Kernel: %lf\n", time1/1000.0, time2/1000.0);

	printf("args[3].size: %d\n", args[3].size);
	printf("total numbers: %d\n", args[3].size/sizeof(double));
#if 0
	for (i = 0; i < args[3].size / sizeof(double); i++) {
	//for (i = 0; i < 10; i++) {
		printf("%lf\n", ((double*)output)[i]);
	}
#endif
#if 0
	int fd = open("/tmp/myfile", O_RDWR | O_APPEND | O_CREAT);
	write(fd, output, args[3].size);
#endif

close_session:
        if (vaccel_sess_free(&sess) != VACCEL_OK) {
                fprintf(stderr, "Could not clear session\n");
                return 1;
        }
        vaccel_prof_region_stop(&savgol_op_stats);

        return ret;
}

#if 0
int main(int argc, char **argv)
{
	savgol_GPU(argc, argv);
	return 0;
}
#endif
__attribute__((constructor))
	static void vaccel_blackscholes_init(void)
{
}

__attribute__((destructor))
	static void vaccel_blackscholes_fini(void)
{
	vaccel_prof_region_print(&savgol_op_stats);
}
