# ex


#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/sched.h>

#define PROCFS_MAX_SIZE 1024
#define PROCFS_NAME "pidinfo"

static char procfs_buffer[PROCFS_MAX_SIZE];
static unsigned long procfs_buffer_size = 0;
static struct proc_dir_entry *proc_file;

static int pidinfo_read(char *buffer, char **buffer_location, off_t offset, int buffer_length, int *eof, void *data) {
    int ret;
    struct task_struct *task;
    pid_t pid;

    if (offset > 0) {
        ret = 0;
    } else {
        pid = simple_strtol(data, NULL, 10);
        task = pid_task(find_vpid(pid), PIDTYPE_PID);

        if (task == NULL) {
            ret = sprintf(procfs_buffer, "No task with pid %d\n", pid);
        } else {
            ret = sprintf(procfs_buffer, "Command: %s\nPID: %d\nState: %ld\n", task->comm, task_pid_nr(task), task->state);
        }

        memcpy(buffer, procfs_buffer, ret);
    }

    return ret;
}

static int pidinfo_write(struct file *file, const char *buffer, unsigned long count, void *data) {
    if (count > PROCFS_MAX_SIZE) {
        procfs_buffer_size = PROCFS_MAX_SIZE;
    } else {
        procfs_buffer_size = count;
    }

    if (copy_from_user(procfs_buffer, buffer, procfs_buffer_size)) {
        return -EFAULT;
    }

    return procfs_buffer_size;
}

static int __init pidinfo_init(void) {
    proc_file = proc_create(PROCFS_NAME, 0644, NULL, &proc_fops);

    if (proc_file == NULL) {
        remove_proc_entry(PROCFS_NAME, NULL);
        printk(KERN_ALERT "Error: Could not initialize /proc/%s\n", PROCFS_NAME);
        return -ENOMEM;
    }

    printk(KERN_INFO "/proc/%s created\n", PROCFS_NAME);
    return 0;
}

static void __exit pidinfo_exit(void) {
    remove_proc_entry(PROCFS_NAME, NULL);
    printk(KERN_INFO "/proc/%s removed\n", PROCFS_NAME);
}

static struct file_operations proc_fops = {
    .read = pidinfo_read,
    .write = pidinfo_write,
};

module_init(pidinfo_init);
module_exit(pidinfo_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
