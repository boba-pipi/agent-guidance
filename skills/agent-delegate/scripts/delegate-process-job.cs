using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

namespace AgentDelegate;

/// <summary>Owns a Windows job that terminates its assigned processes when disposed.</summary>
public sealed class ProcessJob : IDisposable {
    private readonly SafeFileHandle _handle;

    /// <summary>Creates an unnamed job with kill-on-close process ownership.</summary>
    public ProcessJob() {
        _handle = new SafeFileHandle(CreateJobObject(IntPtr.Zero, null), true);
        if (_handle.IsInvalid) {
            throw new Win32Exception(Marshal.GetLastWin32Error());
        }
        var limits = new ExtendedLimits { basic = new BasicLimits { flags = 0x2000 } };
        if (!SetInformationJobObject(_handle, 9, ref limits, (uint)Marshal.SizeOf<ExtendedLimits>())) {
            var error = Marshal.GetLastWin32Error();
            _handle.Dispose();
            throw new Win32Exception(error);
        }
    }

    /// <summary>Attaches a live child; a command that already exited requires no assignment.</summary>
    public bool Attach(Process process) {
        if (AssignProcessToJobObject(_handle, process.SafeHandle)) {
            return true;
        }
        var error = Marshal.GetLastWin32Error();
        if (process.HasExited) {
            return false;
        }
        throw new Win32Exception(error, "Could not establish delegate process ownership.");
    }

    /// <summary>Terminates remaining job members and releases the native handle.</summary>
    public void Dispose() => _handle.Dispose();

    [StructLayout(LayoutKind.Sequential)]
    private struct BasicLimits {
        public long processTime, jobTime;
        public uint flags;
        public UIntPtr minimumWorkingSet, maximumWorkingSet;
        public uint activeProcesses;
        public UIntPtr affinity;
        public uint priority, scheduling;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct IoCounters {
        public ulong readOperations, writeOperations, otherOperations;
        public ulong readBytes, writeBytes, otherBytes;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ExtendedLimits {
        public BasicLimits basic;
        public IoCounters io;
        public UIntPtr processMemory, jobMemory, peakProcessMemory, peakJobMemory;
    }

    [DllImport("kernel32.dll", EntryPoint = "CreateJobObjectW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateJobObject(IntPtr attributes, string name);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetInformationJobObject(SafeFileHandle job, int informationClass,
        ref ExtendedLimits limits, uint length);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool AssignProcessToJobObject(SafeFileHandle job, SafeProcessHandle process);
}
