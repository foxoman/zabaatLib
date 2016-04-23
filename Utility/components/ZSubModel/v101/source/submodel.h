#ifndef SUBMODEL_H
#define SUBMODEL_H

#include <QObject>
#include <QDebug>
//#include <QAbstractListModel>
#include <QJSValue>
#include <QJSValueList>
#include <vector>
#include <QList>
#include <QStringList>
#include "mstimer.h"
#include "nanotimer.h"
#include <QtQml/private/qqmllistmodel_p.h>    //dont think this helps since we dont actually want to copy

typedef QHash<int,QByteArray>         QRoles;
typedef QHashIterator<int,QByteArray> QRoleItr;

using namespace std;
class submodel : public QQmlListModel {
    Q_OBJECT
    Q_PROPERTY(QQmlListModel *sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QList<int> indexList READ indexList WRITE setIndexList NOTIFY indexListChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool readOnly READ readOnly WRITE setReadOnly NOTIFY readOnlyChanged)


protected:
    QRoles roleNames() const {
        if(source == nullptr) {
            return QRoles();
        }
        return source->roleNames();
    }


public:
    submodel(QObject * parent = 0) : QQmlListModel(parent) {
        m_count = 0;
        m_readOnly = true;
        source = NULL;
        nil = QJSValue::NullValue;
        clear() ;
     }

    //METHODS WE MUST PROVIDE!!
    QModelIndex index(int row, int column, const QModelIndex &parent) const
    {
        if(source == nullptr || row < 0 || row > indices.length())
            return QModelIndex();
        return source->index(indices[row],column,parent);
    }

    QVariant data(int index, int role) const {
        if(source == nullptr || index < 0 || index > indices.length())
            return nil.toVariant();

        int relativeIdx = indices[index];
        if(relativeIdx < 0 || relativeIdx >= srcSize() )
            return nil.toVariant();

        return source->data(index,role);
    }
    QVariant data(const QModelIndex &index, int role) const {
        if(!index.isValid() || source == nullptr || index.row() < 0 || index.row() > indices.length())
            return nil.toVariant();


        int relativeIdx = indices[index.row()];
        if(relativeIdx < 0 || relativeIdx >= srcSize() )
            return nil.toVariant();

        //have to constract a QModelIndex like a boss from our QList
        return source->data(relativeIdx,role);
    }

    int count() const{  //TO ENABLE MODELCEPTIOn,OMG!@
//        qDebug() << objectName() << ".count(" << m_count << ")";
        return m_count;
    }
    int rowCount(const QModelIndex &parent = QModelIndex()) const {
        return count();
    }
    void setCount(uint c){
        if(c != m_count){
            m_count = c;
            Q_EMIT countChanged(m_count);
        }
    }

    bool readOnly(){ return m_readOnly; }
    void setReadOnly(bool val){
        if(val != m_readOnly){
            m_readOnly = val;
            Q_EMIT readOnlyChanged();
        }
    }


    QQmlListModel* sourceModel() { return source; }
    void setSourceModel(QObject *src){
        if(src != source) {
            disconnectSignals();

            //beginResetModel();
            source = reinterpret_cast<QQmlListModel *>(src);
            if(source != nullptr) { //connect stuff
                connectSignals(source);
            }
            //endResetModel();

            Q_EMIT sourceModelChanged();
        }
    }


    QList<int> indexList() {
        return indices;
    }
    void setIndexList(QList<int> intArr){
//        qDebug() << objectName() << "::setIndexList" << intArr;
        safeList(intArr); //so everyuthing is kosher! i > 0  && i < rowCount of sourceModel

        //since we are going to overwrite this indexList, let's make sure we tell the view that we
        //don't need those delegated
        clear();

        indices = intArr;
        Q_EMIT indexListChanged();

        indexListSignals();
    }

    Q_INVOKABLE QStringList getRoleNames() {
        QStringList r;
        QRoleItr i(roleNames());
        while(i.hasNext()) {
            i.next();
            r.append(QString(i.value()));
        }
        return r;
    }
    Q_INVOKABLE QQmlV4Handle get(int row){
        if(row >= 0 && row < indices.length() && source != nullptr) {
            return sourceGet(indices[row]);
        }
        return QQmlListModel::get(row); //YAY, this will return undefined!!
    }
    Q_INVOKABLE QQmlV4Handle sourceGet(int row){
        return source != nullptr ? source->get(row) : get(-1);
    }

    Q_INVOKABLE void set(int index, const QQmlV4Handle & h){
       if(m_readOnly)
            qWarning() << "submodel.h::set called w/o disabling readOnly";
       else if(index >= 0 && index < indices.length() && source != nullptr)
           source->set(indices[index] , h);

    }
    Q_INVOKABLE void insert(QQmlV4Function *args) {
        if(m_readOnly)
            qWarning() << "submodel.h::insert use insert on the sourceModel. not this";
        else if(source != nullptr){
            source->insert(args);
        }
    }
    Q_INVOKABLE void append(QQmlV4Function *args){
        if(m_readOnly)
            qWarning() << "submodel.h::append use append on the sourceModel. not this";
        else if(source != nullptr)
            source->append(args);
    }
    Q_INVOKABLE void remove(QQmlV4Function *args){
        if(m_readOnly)
            qWarning() << "submodel.h::remove use remove on the sourceModel. not this";
        else if(source != nullptr){
            source->remove(args);
        }
    }
    Q_INVOKABLE void setProperty(int index, const QString &property, const QVariant &value){
        if(m_readOnly)
            qWarning() << "submodel.h::setProperty use setProperty on the sourceModel. not this";
        else if(index >= 0 && index < indices.length() && source != nullptr) {
            source->setProperty(indices[index] , property , value);
        }
    }

    Q_INVOKABLE void addToIndexList(int idx) {
        if(source == nullptr || indices.contains(idx) || idx < 0 || idx >= srcSize())
            return;

        beginInsertRows(QModelIndex(), indices.length(), indices.length());  //cause we will put it
        indices.append(idx);
        Q_EMIT indexListChanged();
        setCount(indices.length());
        endInsertRows();
    }
    Q_INVOKABLE void removeFromIndexList(int idx){
        int indexOf;
        if(-1 != (indexOf = indices.indexOf(idx))){
            beginRemoveRows(QModelIndex(), indexOf, indexOf);
            indices.removeAt(indexOf);
            endRemoveRows();
            setCount(indices.length());
        }
    }
    Q_INVOKABLE void clear() {
        if(indices.length() > 0) {
            beginRemoveRows(QModelIndex(), 0, indices.length() - 1);
            endRemoveRows();
            indices.clear();
            Q_EMIT indexListChanged();
        }
        setCount(indices.length());
    }


    Q_INVOKABLE void emitDataChanged(int start, int end, const QVector<int> &roles = QVector<int>()){
//        Q_EMIT dataChanged(index(start) ,index(end) , roles);
//        QModelIndex topLeft(start, 0, nullptr, source );
//        QModelIndex bottomRight(end, 0, nullptr, source );
//        auto topLeft     = QAbstractListModel::index(start,0, QModelIndex());
//        auto bottomRight = QAbstractListModel::index(end,0, QModelIndex());
        Q_EMIT dataChanged(QAbstractListModel::index(start,0, QModelIndex()),
                           QAbstractListModel::index(end,0, QModelIndex()) ,
                           roles);
    }

//    Q_INVOKABLE uint getActualIndex(int idx) {
//        return indices.indexOf(idx);
//    }

    Q_INVOKABLE void move(uint from, uint to, uint n){
        if(n <= 0 || from==to)
            return;

        if(!moveIsLegal(from,to,n)){
            qWarning() << "submodel.h :: move out of range: " << n << " elements from " << from << " to " << to;
            return;
        }


        beginMoveRows(QModelIndex(), from, from + n - 1, QModelIndex(), to > from ? to + n : to);

        //do move operation!
//        qDebug() << "BEGIN MOVE OP[" << start << "-" << end << "] to " << to;
        int realFrom = from;
        int realTo = to;
        int realN = n;
//        qDebug() << "FIGURING OUT WHAT GON HAPPEN";
        if (from > to) {
            // Only move forwards - flip if backwards moving
            int tfrom = from;
            int tto = to;
            realFrom = tto;
            realTo = tto+n;
            realN = tfrom-tto;
        }

        QList<int> store;
//        qDebug () << "BEFORE " << indices;

//        qDebug() << "BEGIN LOOP 1";
        for(int i = 0; i < (realTo-realFrom); ++i){
            store.append(indices[realFrom+realN+i]);
        }
//        qDebug() << "BEGIN LOOP 2";
        for(int i = 0; i < realN; ++i){
            store.append(indices[realFrom+i]);
        }
//        qDebug() << "BEGIN LOOP 3";
        for(int i = 0; i < store.length(); ++i){
            indices[realFrom+i] = store[i];
        }
//        qDebug() << "END " << indices;


        endMoveRows();
//        Q_EMIT endMoveRows();
    }

    Q_INVOKABLE int actualIdx(int idx){
        if(idx >= 0 && idx < indices.length()){
            return indices[idx];
        }
        return -1;
    }


signals :
    void sourceModelChanged();
    void countChanged(int);
    void indexListChanged();

    void source_rowsInserted(int start, int end, int count);
    void source_dataChanged(int idx, int refIdx, QVector<int> roles);
    void source_rowsMoved();
    void source_rowsRemoved();

    void source_modelReset();
    void readOnlyChanged();


private:
    QQmlListModel *source;  //the sourceModel
    QList<int> indices;     //indices that determine the subset of source
    QJSValue   nil;         //for ease of use mang!!
    uint       m_count;
    bool       m_readOnly;


    //These are the connections (signals) we listen to from the source model!
    QMetaObject::Connection conn_rowsInserted;
    QMetaObject::Connection conn_rowsMoved;
    QMetaObject::Connection conn_rowsRemoved;
    QMetaObject::Connection conn_dataChanged;
    QMetaObject::Connection conn_modelReset;

    QVector<int> rolesVecInt() {
        return roleNames().keys().toVector();
    }

    int srcSize() const {
        if(source == nullptr)
            return 0;

        int value = source->count();
        try {
            submodel &s = dynamic_cast<submodel&>(*source);
    //                qDebug() << "cast succeeded";
            value = s.count();
        }
        catch(std::exception e){
    //            qDebug() << "failed to cast " ;
        }

        return value;
    }
    bool moveIsLegal(int from, int to, int n){
        return !(from+n > rowCount() || to+n > rowCount() || from < 0 || to < 0 || n < 0);
    }

    void connectSignals(QQmlListModel *src) {
        conn_rowsInserted = connect(src, &QQmlListModel::rowsInserted, this, &submodel::__rowsInserted);
        conn_rowsMoved    = connect(src, &QQmlListModel::rowsMoved   , this, &submodel::__rowsMoved   );
        conn_rowsRemoved  = connect(src, &QQmlListModel::rowsRemoved , this, &submodel::__rowsRemoved );
        conn_dataChanged  = connect(src, &QQmlListModel::dataChanged , this, &submodel::__dataChanged );
        conn_modelReset   = connect(src, &QQmlListModel::modelReset  , this, &submodel::__modelReset  );
    }
    void disconnectSignals() {
        disconnect(conn_rowsInserted);
        disconnect(conn_rowsMoved);
        disconnect(conn_rowsRemoved);
        disconnect(conn_dataChanged);
        disconnect(conn_modelReset);
    }

    void __rowsInserted(const QModelIndex &parent, int start, int end){
        //since we cant turn QVariant elems (from sourcemodel) into QJSValue here. We have to let JS handle this
        //and run its filter function.
        int count = end - start + 1;
//        qDebug() << objectName() << "emitting source_rowsInserted" << start<< end << count;
        Q_EMIT source_rowsInserted(start,end,count);
    }
    void __rowsRemoved(const QModelIndex &parent , int start, int end) {
        int count = end - start + 1 ; //this is the amount of things that need it's indexes updated
        int r;
        for(int i = indices.length() -1; i >=0; --i){
            r = indices[i];
            if(r >= start && r <= end){
                Q_EMIT beginRemoveRows(QModelIndex(), i, i);
                indices.removeAt(i);
                Q_EMIT endRemoveRows();
            }
            else if(r > end){
                indices[i] -= count;
                //This has adjusted the indices to match? Shouldn't really have to trigger anything I think.
            }
        }


        Q_EMIT source_rowsRemoved();
    }
    void __rowsMoved(const QModelIndex &parent, int fromStart, int fromEnd, const QModelIndex &destination, int row) {
//        qDebug() << indices;

        int count = fromEnd - fromStart +1;
        int toStart, toEnd;
        if(row < fromStart){
            toStart = row;
        }
        else if(row > fromEnd){
            toStart = row - count;
        }
        toEnd  = toStart + count - 1;

        int i, r, dist;
        if(fromStart > toStart){    //original elements moved up!
            dist = fromStart - toStart;
            for(i = 0; i < indices.length(); ++i){
                r   = indices[i];
                if(r >= toStart && r <= fromEnd){   //only these things will be affected!!
                    if(r >= fromStart && r <= fromEnd){ //if its the stuff moving up
                        indices[i] = r - dist;
                    }
                    else {  //its the stuff moving down
                        indices[i] = r + count;
                    }
                }
            }
            //WE need to tell that data was changed (so that the DATA function works properly)
            emitDataChanged(0, indices.length()-1 , rolesVecInt() );
        }
        else if(fromStart < toStart) {  //original elements were moved down!
            dist              = toStart - fromStart;
            int elemsInMiddle = toStart - fromEnd - 1;
            for(i = 0; i < indices.length(); ++i){
                r   = indices[i];
                if(r >= fromStart && r <= toEnd){
                    if(r >= fromStart && r <= fromEnd){ //is in from
                        indices[i] = r + dist;
                    }
                    else if(r >= toStart && r <= toEnd){ //is in the to SEction
                        indices[i] = r - dist + elemsInMiddle;
                    }
                    else {  //is in the middle
                        indices[i] = r - count;
                    }
                }
            }
            //WE need to tell that data was changed (so that the DATA function works properly)
            emitDataChanged(0, indices.length() - 1 , rolesVecInt() );
        }
//        qDebug() << indices;
        Q_EMIT indexListChanged();
        Q_EMIT source_rowsMoved();

    }
    void __dataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight, const QVector<int> &roles = QVector<int>()) {
        //since we cant turn QVariant elems (from sourcemodel) into QJSValue here. We have to let JS handle this
        //and run its filter function.
//        qDebug() << objectName() <<"'s source changed" << topLeft.row() << "," << topLeft.column() << "::" << bottomRight.row() << "::" << bottomRight.column();
        int actualIdx = topLeft.row();
        int refIdx = -1;
        for(int i = 0; i < indices.length(); ++i){
            if(indices[i] == actualIdx){
                refIdx = i;
                break;
            }
        }

        Q_EMIT source_dataChanged(actualIdx, refIdx, roles);
    }
    void __modelReset() {
        Q_EMIT source_modelReset();
    }






    void safeList(QList<int> &indices){
        if(source == nullptr){
            indices.clear();
        }

        for(int i = indices.length() - 1 ; i >= 0; --i) {
            int row = indices[i];
            if(row < 0 || row > srcSize())
                indices.removeAt(i);
        }
    }
    void indexListSignals(){
        if(source == nullptr)
            return;

        setCount(indices.length());
//        qDebug() << "about to begin inserting rows" << rowCount() << count();
        for(int i = 0; i < indices.length(); ++i) {
            int row = indices[i];
            if(row > -1 && row < srcSize()){
                beginInsertRows(QModelIndex(), i, i);
                endInsertRows();
            }
            else {
                qWarning() << objectName() << "Cannot insert" << row << "because source range is [0-" << srcSize() << "]";
            }
        }

    }







};


#endif // SUBMODEL_H