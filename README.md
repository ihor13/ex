# ex


#include <linux/init.h>
#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/sched/signal.h>
#include <linux/sched/task.h>
#include <linux/uaccess.h>

#define PROC_NAME "pid"

static struct proc_dir_entry *proc_file;
static pid_t pid;

static int proc_read(char *page, char **start, off_t off, int count, int *eof, void *data) {
    struct task_struct *task;
    char buf[256];
    int len = 0;
    
    *eof = 1;
    
    task = pid_task(find_vpid(pid), PIDTYPE_PID);
    if (task) {
        len += snprintf(buf + len, sizeof(buf) - len, "Command: %s\n", task->comm);
        len += snprintf(buf + len, sizeof(buf) - len, "PID: %d\n", pid);
        len += snprintf(buf + len, sizeof(buf) - len, "State: %ld\n", task->state);
    } else {
        len += snprintf(buf + len, sizeof(buf) - len, "Invalid PID\n");
    }
    
    if (off >= len) {
        *eof = 0;
        return 0;
    }
    
    len -= off;
    if (len > count) {
        len = count;
    }
    
    memcpy(page, buf + off, len);
    return len;
}

static int proc_write(struct file *file, const char __user *buffer, unsigned long count, void *data) {
    char buf[16];
    int len;
    
    len = min((int) count, (int) sizeof(buf) - 1);
    if (copy_from_user(buf, buffer, len)) {
        return -EFAULT;
    }
    
    buf[len] = '\0';
    if (sscanf(buf, "%d", &pid) != 1) {
        return -EINVAL;
    }
    
    return len;
}

static int __init proc_init(void) {
    proc_file = proc_create(PROC_NAME, 0666, NULL, &proc_fops);
    if (!proc_file) {
        return -ENOMEM;
    }
    
    return 0;
}

static void __exit proc_exit(void) {
    remove_proc_entry(PROC_NAME, NULL);
}

module_init(proc_init);
module_exit(proc_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A kernel module that displays a task's information based on its pid");


