#g_io_add_watch
调用的g_main_context_add_poll_unlocked把GPollFD放到GMainContext上：

  if (nextrec)
    nextrec->prev = newrec;
  else
    context->poll_records_tail = newrec;

这些FD由g_main_loop_run中poll。

#g_main_loop_new g_main_loop_run
g_main_loop_new在一个GMainContext创建一个GMainLoop。会有一个默认的GMainContext。


#示例程序编译
gcc $(pkg-config --cflags glib-2.0) glib-mainloop.c -o glib-mainloop $(pkg-config --libs glib-2.0)

在ubuntu 12.04上的那个GCC：
gcc $(pkg-config --cflags --libs glib-2.0) glib-mainloop.c -o glib-mainloop会出错，就是-l这个要放在-o后面？

glib-mainloop.c:

#include <glib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

GMainLoop *loop;

static gboolean io_callback (GIOChannel * io, GIOCondition condition, gpointer data)
{
  gchar in;
  GError *error = NULL;

  switch (g_io_channel_read_chars (io, &in, 1, NULL, &error)) {

    case G_IO_STATUS_NORMAL:
      if ('q' == in) {
        g_main_loop_quit (loop);
        return FALSE;
      } else {
        g_warning ("recv char=%c", in);
      }

      return TRUE;

    case G_IO_STATUS_ERROR:
      g_printerr ("IO error: %s\n", error->message);
      g_error_free (error);

      return FALSE;

    case G_IO_STATUS_EOF:
      g_warning ("No input data available");
      return TRUE;

    case G_IO_STATUS_AGAIN:
      return TRUE;

    default:
      g_return_val_if_reached (FALSE);
      break;
  }

  return FALSE;
}

int
main (int argc, char *argv[])
{
  GIOChannel *io = NULL;

  guint io_watch_id = 0;

  if (!g_thread_supported ()) {
    g_thread_init (NULL);
  }

  loop = g_main_loop_new (NULL, FALSE);

  /* standard input callback */
  io = g_io_channel_unix_new (STDIN_FILENO);
  io_watch_id = g_io_add_watch (io, G_IO_IN, io_callback, NULL);
  g_io_channel_unref (io);

  g_message ("Running...");

  g_main_loop_run (loop);

  g_message ("Returned, stopping playback");

  if (loop)
    g_main_loop_unref (loop);

  return 0;
}

