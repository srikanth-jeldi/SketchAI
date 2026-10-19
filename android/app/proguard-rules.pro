# WorkManager's transitive Room 2.2 database is instantiated by reflection.
# Its consumer rules preserve the name but R8 can remove the no-arg constructor,
# crashing InitializationProvider before Flutter starts in optimized builds.
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
