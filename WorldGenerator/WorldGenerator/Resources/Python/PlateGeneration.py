

import time
import math
from random import random
import scipy.spatial as spatial
import numpy as np

EPSILON = 0.25
PHI = (1 + math.sqrt(5)) / 2  # golden ratio


def generate_uniform_points_on_sphere(pointsNum:int, sphereSize:float, randomFactor:float) -> np.ndarray:
    """
    Generates a list of points on the surface of a sphere, placed semi uniformly

    Args:
        pointsNum (int): The number of points to generate.
        sphereSize (float): The radius of the sphere.
        randomFactor (float): A factor to introduce randomness in the point generation, value between 0 and 1

    Returns:
        list: A list of tuples representing the coordinates of the points.
    """
    points = []
    points = np.linspace(0, pointsNum - 1, pointsNum) # generate points in a linear space
    points = np.array([((points)/PHI)%1, points/(pointsNum - 1)]) # calculate coordinates on plane
    points = np.array([2*np.pi * points[0], np.acos(1-2*points[1])]) # transform to sphere(polar coordinates)
    points = np.array([sphereSize * np.cos(points[0]) * np.sin(points[1]), sphereSize * np.sin(points[0]) * np.sin(points[1]), sphereSize * np.cos(points[1])]) # transform to cartesian coordinates
    points = points.T # transpose to get the correct shape

    return points

def generate_random_points_on_sphere(pointsNum:int, sphereSize:float) -> np.ndarray:
    """
    Generates a list of random points on the surface of a sphere.

    Args:
        pointsNum (int): The number of points to generate.
        sphereSize (float): The radius of the sphere.

    Returns:
        list: A list of tuples representing the coordinates of the points.
    """
    rng = np.random.default_rng()
    points = rng.integers(1, pointsNum*5, pointsNum) # generate random points in a linear space
    points = np.array([(points/PHI)%1, points/((pointsNum*5) - 1)]) # calculate coordinates on plane
    points = np.array([2*np.pi * points[0], np.acos(1-2*points[1])]) # transform to sphere(polar coordinates)
    points = np.array([sphereSize * np.cos(points[0]) * np.sin(points[1]), sphereSize * np.sin(points[0]) * np.sin(points[1]), sphereSize * np.cos(points[1])]) # transform to cartesian coordinates
    points = points.T # transpose to get the correct shape
    return points

def generate_voronoi(points:np.ndarray, sphereSize:float)-> spatial.SphericalVoronoi:
    """
    Generates a Voronoi diagram based on the given points on the surface of a sphere.

    Args:
        points (list): A list of tuples representing the coordinates of the points.
        sphereSize (float): The radius of the sphere.

    Returns:
        list: A list of Voronoi cells, each represented as a list of points.
        vertices (list): A list of vertices of the Voronoi cells.
        region_counts (list): A list of the number of vertices in each Voronoi cell.
        regions (list): A list of the indices of the vertices that make up each Voronoi cell.
    """
    voronoi = spatial.SphericalVoronoi(points, radius=sphereSize, center=[0, 0, 0], threshold=1e-6)
    vertices = voronoi.vertices
    vertices = vertices.T
    vertices = np.array([np.atan2(vertices[1], vertices[0])* 180/np.pi, np.arcsin(np.clip(vertices[2]/sphereSize, -1.0, 1.0))* 180/np.pi]) # transform to lat/lng
    vertices = vertices.T



    region_counts = np.fromiter([len(region) for region in voronoi.regions], dtype=int)
    regions = np.concatenate(voronoi.regions)

    return [np.ascontiguousarray(vertices, dtype=np.float64), np.ascontiguousarray(regions, dtype=np.int32), np.ascontiguousarray(region_counts, dtype=np.int32)]

def assign_points_to_regions(points:np.ndarray, regions:np.ndarray)-> np.ndarray:
    """
    assigns polygons into bigger regions, based on polygons beeing inside region
    """
    kd_tree = spatial.KDTree(regions, 1, False, balanced_tree=False) # create a kd tree for the centers of regions
    response = kd_tree.query(points, 1) # query the kd tree for the closest region to each point
    return response[1]


platesNum = 15
segmentsNum = 10000
planetSize = 5000
i=0
loop_num = 100
while i<loop_num:
    points =generate_uniform_points_on_sphere(segmentsNum, planetSize, 0)
    regionPoints = generate_random_points_on_sphere(platesNum, planetSize)
    pointsToRegions = assign_points_to_regions(points, regionPoints)
    distinct_regions = np.unique(pointsToRegions)
    print(len(distinct_regions))
    i+=1