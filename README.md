# ex


#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/sched.h>
#include <linux/uaccess.h>

#define MAX_BUF_SIZE 256

static struct proc_dir_entry *proc_file;
static char proc_buffer[MAX_BUF_SIZE];
static unsigned long proc_buffer_size = 0;
static int pid = 0;

static int proc_write(struct file *file, const char __user *buffer,
                      unsigned long count, void *data)
{
    if (count > MAX_BUF_SIZE) {
        printk(KERN_INFO "proc_write: buffer size too large!\n");
        return -EFAULT;
    }
    if (copy_from_user(proc_buffer, buffer, count)) {
        printk(KERN_INFO "proc_write: failed to copy data from user space!\n");
        return -EFAULT;
    }
    proc_buffer[count] = '\0';
    kstrtoint(proc_buffer, 10, &pid);
    return count;
}

static int proc_read(char *page, char **start, off_t offset,
                     int count, int *eof, void *data)
{
    int len = 0;
    struct task_struct *task;

    if (offset > 0) {
        *eof = 1;
        return 0;
    }
    if (pid == 0) {
        len += sprintf(page + len, "Please write a valid process ID to /proc/pid\n");
        return len;
    }
    task = pid_task(find_vpid(pid), PIDTYPE_PID);
    if (task == NULL) {
        len += sprintf(page + len, "Invalid process ID %d\n", pid);
        return len;
    }
    len += sprintf(page + len, "Process ID: %d\n", pid);
    len += sprintf(page + len, "Process Name: %s\n", task->comm);
    len += sprintf(page + len, "Process State: %ld\n", task->state);
    return len;
}

static int __init my_module_init(void)
{
    printk(KERN_INFO "my_module loaded\n");
    proc_file = proc_create("pid", 0666, NULL, &proc_fops);
    if (proc_file == NULL) {
        printk(KERN_ERR "proc_create failed!\n");
        return -ENOMEM;
    }
    return 0;
}

static void __exit my_module_exit(void)
{
    printk(KERN_INFO "my_module unloaded\n");
    proc_remove(proc_file);
}

static struct file_operations proc_fops = {
    .read = proc_read,
    .write = proc_write,
};

module_init(my_module_init);
module_exit(my_module_exit);
MODULE_LICENSE("GPL");
