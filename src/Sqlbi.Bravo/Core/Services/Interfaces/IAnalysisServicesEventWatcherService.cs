﻿using System;
using System.Threading.Tasks;

namespace Sqlbi.Bravo.Core.Services.Interfaces
{
    internal interface IAnalysisServicesEventWatcherService
    {
        event EventHandler<AnalysisServicesEventWatcherEventArgs> OnEvent;

        event EventHandler<AnalysisServicesEventWatcherConnectionStateArgs> OnConnectionStateChanged;

        Task ConnectAsync();

        Task DisconnectAsync();
    }
}