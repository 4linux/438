<%@ page import="java.util.*, java.lang.management.*, java.util.concurrent.*" %>
<%@ page import="net.bytebuddy.*, net.bytebuddy.dynamic.*, net.bytebuddy.dynamic.loading.*" %>
<html>
<head>
    <title>JVM Monitoring App</title>
</head>
<body>
    <h1>JVM Monitoring App</h1>

    <%
        // Heap Allocation
        List<byte[]> memoryConsumers = (List<byte[]>) application.getAttribute("memoryConsumers");
        if (memoryConsumers == null) {
            memoryConsumers = new ArrayList<>();
            application.setAttribute("memoryConsumers", memoryConsumers);
        }

        // CPU Load Simulation
        ExecutorService cpuExecutor = (ExecutorService) application.getAttribute("cpuExecutor");
        if (cpuExecutor == null) {
            cpuExecutor = Executors.newCachedThreadPool();
            application.setAttribute("cpuExecutor", cpuExecutor);
        }

        // Thread Tracking
        List<Thread> threadList = (List<Thread>) application.getAttribute("threadList");
        if (threadList == null) {
            threadList = new ArrayList<>();
            application.setAttribute("threadList", threadList);
        }

        // Class Instances Tracking (to avoid GC)
        List<Object> loadedClassInstances = (List<Object>) application.getAttribute("loadedClassInstances");
        if (loadedClassInstances == null) {
            loadedClassInstances = new ArrayList<>();
            application.setAttribute("loadedClassInstances", loadedClassInstances);
        }

        // Actions
        String action = request.getParameter("action");

        if ("allocateMemory".equals(action)) {
            byte[] chunk = new byte[20 * 1024 * 1024];
            memoryConsumers.add(chunk);
            out.println("<p>20MB alocados com sucesso.</p>");
        } else if ("resetMemory".equals(action)) {
            memoryConsumers.clear();
            out.println("<p>Memoria resetada (referencias limpas).</p>");
        } else if ("cpuLoad".equals(action)) {
            cpuExecutor.submit(() -> {
                long end = System.currentTimeMillis() + 60000;
                while (System.currentTimeMillis() < end) {
                    Math.pow(Math.random(), Math.random());
                }
            });
            out.println("<p>Carga de CPU gerada por 10 segundos.</p>");
        } else if ("gcActivity".equals(action)) {
            for (int i = 0; i < 50_000_000; i++) {
                Object obj = new Object();
                obj.toString(); // prevent optimization
            }
            System.gc();
            out.println("<p>GC solicitado apos criar 50 milhoes de objetos temporarios.</p>");
        } else if ("newThread".equals(action)) {
            Thread t = new Thread(() -> {
                try { Thread.sleep(60000); } catch (InterruptedException ignored) {}
            });
            t.start();
            threadList.add(t);
            out.println("<p>Thread criada (dorme por 60s).</p>");
        } else if ("newDaemonThread".equals(action)) {
            Thread t = new Thread(() -> {
                while (true) {
                    try { Thread.sleep(1000); } catch (InterruptedException ignored) {}
                }
            });
            t.setDaemon(true);
            t.start();
            threadList.add(t);
            out.println("<p>Daemon thread iniciada (loop infinito).</p>");
        } else if ("loadClasses".equals(action)) {
            try {
                ByteBuddy byteBuddy = new ByteBuddy();
                for (int i = 0; i < 100; i++) {
                    String className = "com.example.GeneratedClass" + UUID.randomUUID().toString().replace("-", "");
                    Class<?> dynamicClass = byteBuddy
                        .subclass(Object.class)
                        .name(className)
                        .make()
                        .load(getClass().getClassLoader(), ClassLoadingStrategy.Default.WRAPPER)
                        .getLoaded();

                    Object instance = dynamicClass.getDeclaredConstructor().newInstance();
                    loadedClassInstances.add(instance); // keep reference alive
                }
                out.println("<p>100 classes carregadas dinamicamente.</p>");
            } catch (Exception e) {
                out.println("<p>Erro ao carregar classes: " + e.getMessage() + "</p>");
            }
        }
    %>

    <h2>Heap</h2>
    <%
        Runtime runtime = Runtime.getRuntime();
        long usedMemory = runtime.totalMemory() - runtime.freeMemory();
        long maxMemory = runtime.maxMemory();

        out.println("<p>Used memory: " + usedMemory / (1024 * 1024) + " MB</p>");
        out.println("<p>Total memory (current heap): " + runtime.totalMemory() / (1024 * 1024) + " MB</p>");
        out.println("<p>Max memory (heap max): " + maxMemory / (1024 * 1024) + " MB</p>");
        out.println("<p>Memory chunks allocated: " + memoryConsumers.size() + "</p>");
    %>
    <form method="post">
        <button name="action" value="allocateMemory">Allocate more memory (~20MB)</button>
        <button name="action" value="resetMemory">Reset memory</button>
    </form>

    <h2>CPU Usage</h2>
    <form method="post">
        <button name="action" value="cpuLoad">Generate CPU load (~10s)</button>
    </form>

    <h2>GC Activity</h2>
    <form method="post">
        <button name="action" value="gcActivity">Generate GC activity</button>
    </form>

    <h2>Threads</h2>
    <%
        ThreadMXBean threadBean = ManagementFactory.getThreadMXBean();
        out.println("<p>Live threads: " + threadBean.getThreadCount() + "</p>");
        out.println("<p>Daemon threads: " + threadBean.getDaemonThreadCount() + "</p>");
    %>
    <form method="post">
        <button name="action" value="newThread">Create new thread (sleeps 60s)</button>
        <button name="action" value="newDaemonThread">Create daemon thread (infinite)</button>
    </form>

    <h2>Loaded Classes</h2>
    <%
        ClassLoadingMXBean classBean = ManagementFactory.getClassLoadingMXBean();
        out.println("<p>Total loaded classes: " + classBean.getTotalLoadedClassCount() + "</p>");
        out.println("<p>Currently loaded classes: " + classBean.getLoadedClassCount() + "</p>");
        out.println("<p>Unloaded classes: " + classBean.getUnloadedClassCount() + "</p>");
        out.println("<p>Tracked dummy instances (to avoid GC): " + loadedClassInstances.size() + "</p>");
    %>
    <form method="post">
        <button name="action" value="loadClasses">Load new dummy classes</button>
    </form>

</body>
</html>
