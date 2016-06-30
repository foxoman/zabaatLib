#ifndef ZFILEIO_PLUGIN_H
#define ZFILEIO_PLUGIN_H

#include <QQmlExtensionPlugin>
#include "zfilerw.h"
#include "zpaths.h"
#include "zfiledownloader.h"
#include <qqml.h>
#include <QFileInfo>
#include <QList>

class zfileio : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "Zabaat.Utility.FileIO")

public:
    void registerTypes(const char *uri) {
         qmlRegisterType<ZFileRW>(uri , 1, 0, "ZFileOperations");
         qmlRegisterType<ZPaths> (uri , 1, 0, "ZPaths" );
         qmlRegisterType<fileDownloader>(uri, 1,0, "ZFileDownloader");
    }
};


#endif // ZFILEIO_PLUGIN_H
