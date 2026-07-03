\qecho ----------------------------------------------------------------------
\qecho pg_cancel_backend: cancels the CURRENT QUERY only.
\qecho The session stays connected (safer than Session KILL / terminate).
\qecho ----------------------------------------------------------------------
SELECT pg_cancel_backend(:PID) AS cancelled;
