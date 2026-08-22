import numpy as np
import psycopg2
from psycopg2.extras import execute_values

# Connection details
DB_CONFIG = {
    "dbname": "worldGenerator",
    "user": "postgres",
    "password": "st00rmtr@per",
    "host": "localhost",
    "port": 5432
}

def bulk_insert_nodes(cursor, nodes_coords):
    """Inserts nodes into DB and returns generated UUIDs."""
    insert_query = """
        INSERT INTO Nodes (name, geom)
        VALUES %s RETURNING id
    """
    # ST_MakePoint takes (longitude, latitude)
    template = "('node', ST_SetSRID(ST_MakePoint(%s, %s), 4326))"
    
    execute_values(
        cursor, 
        insert_query, 
        nodes_coords, 
        template=template, 
        page_size=5000
    )
    
    # Retrieve auto-generated UUIDs returned by RETURNING id
    node_ids = [row[0] for row in cursor.fetchall()]
    return node_ids

def bulk_insert_ways(cursor, num_ways):
    """Inserts empty Ways into DB and returns generated UUIDs."""
    insert_query = """
        INSERT INTO Ways (name)
        VALUES %s RETURNING id
    """
    ways_data = [(f"Way_{i}",) for i in range(num_ways)]
    
    execute_values(
        cursor, 
        insert_query, 
        ways_data, 
        page_size=5000
    )
    
    way_ids = [row[0] for row in cursor.fetchall()]
    return way_ids

def bulk_insert_ways_nodes(cursor, ways_nodes_data):
    """Inserts way-node junction records."""
    insert_query = """
        INSERT INTO WaysNodes (way_id, node_id, sequence_id)
        VALUES %s
    """
    execute_values(
        cursor, 
        insert_query, 
        ways_nodes_data, 
        page_size=10000
    )

if __name__ == "__main__":
    NUM_NODES = 10000
    NUM_WAYS = 30000
    
    # Generate random coordinates using numpy
    lons = np.random.uniform(-180.0, 180.0, NUM_NODES)
    lats = np.random.uniform(-90.0, 90.0, NUM_NODES)
    
    # Cast to native Python floats to prevent 'np.float64' string formatting issues
    node_coords = [(float(lon), float(lat)) for lon, lat in zip(lons, lats)]

    conn = psycopg2.connect(**DB_CONFIG)
    try:
        with conn.cursor() as cursor:
            print("Inserting Nodes...")
            node_ids = bulk_insert_nodes(cursor, node_coords)

            print("Inserting Ways...")
            way_ids = bulk_insert_ways(cursor, NUM_WAYS)

            print("Generating WaysNodes topology...")
            ways_nodes_records = []
            
            node_ids_arr = np.array(node_ids)

            for way_id in way_ids:
                path_length = np.random.randint(2, 7)
                selected_nodes = np.random.choice(node_ids_arr, size=path_length, replace=False)
                
                for seq_id, node_id in enumerate(selected_nodes):
                    # Ensure node_id is a standard string or UUID type
                    ways_nodes_records.append((way_id, str(node_id), seq_id))

            print(f"Inserting {len(ways_nodes_records)} WaysNodes records...")
            bulk_insert_ways_nodes(cursor, ways_nodes_records)

        conn.commit()
        print("Success! All data committed to Postgres.")

    except Exception as e:
        conn.rollback()
        print(f"Error occurred, transaction rolled back: {e}")
        raise
    finally:
        conn.close()